#!/usr/bin/env bash
# check.sh <fmt>   — the differential gate for one format (DESIGN.md § 3)
# check.sh --selftest — toy smoke + the four red-team cases (§ 5)
#
# Gate: sidecar sanity (non-empty, >=1 numeric field) -> compile gate via
# the PINNED toolchain -> parse sample with the compiled parser -> pull the
# same fields from `ffprobe -of json` via jq -> field-by-field compare.
# Non-zero exit on any failure. Self-checked entries are REPORTED, never
# counted as oracle-backed (Tier-2 enforces their vocabulary).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KSC="$ROOT/toolchain/ksc"

red() { echo "RED: $*" >&2; exit 1; }

validate_sidecar() {
  local sc="$1" base
  [ -f "$sc" ] || red "missing sidecar $sc"

  base="$(basename "$sc")"

  jq -se 'length == 1 and (.[0] | type == "object")' "$sc" >/dev/null 2>&1 \
    || red "$base: sidecar must be one valid JSON object"
  jq -e '.sample | type == "string" and length > 0' "$sc" >/dev/null \
    || red "$base: sample must be a non-empty string"
  jq -e '
    .independence == "self-generated" or
    .independence == "third-party"
  ' "$sc" >/dev/null \
    || red "$base: independence must be self-generated or third-party"
  jq -e '.fields | type == "array"' "$sc" >/dev/null \
    || red "$base: fields must be an array"

  local n num
  n="$(jq '.fields | length' "$sc")"
  [ "$n" -gt 0 ] \
    || red "$base: empty oracle field map (red-team case c)"
  jq -e '
    all(.fields[];
      (.name | type == "string" and length > 0) and
      (.kaitai_path | type == "string" and length > 0) and
      (.ffprobe_path | type == "string" and length > 0) and
      (.kind == "numeric" or .kind == "label")
    )
  ' "$sc" >/dev/null \
    || red "$base: every field needs non-empty paths and kind numeric or label"

  num="$(jq '[.fields[] | select(.kind == "numeric")] | length' "$sc")"
  [ "$num" -gt 0 ] \
    || red "$base: label-only field map — magic re-detection is not parsing (red-team case d)"

  jq -e '
    (.self_checked | type == "array") and
    all(.self_checked[];
      type == "string" and (
        . == "chunk-size-sum == file length" or
        . == "monotonic offsets" or
        . == "declared-count == walked-count"
      )
    ) and
    ((.self_checked | unique | length) == (.self_checked | length))
  ' "$sc" >/dev/null \
    || red "$base: self_checked must contain unique canonical assertion kinds"
}

check_spec() { # <ksy> <sidecar>
  local ksy="$1" sc="$2"
  local fmt; fmt="$(basename "$ksy" .ksy)"
  validate_sidecar "$sc"
  mkdir -p "$ROOT/build"
  # NB: long-form --outdir, never -d — the sbt-generated launcher script
  # swallows -d as its own debug flag instead of passing it to ksc
  "$KSC" --target python --outdir "$ROOT/build" "$ksy" \
    || red "$fmt: compile gate failed (red-team case b path)"
  local sample regime
  sample="$ROOT/$(jq -r .sample "$sc")"
  regime="$(jq -r .independence "$sc")"
  [ -f "$sample" ] || red "$fmt: sample missing: $sample"
  local parsed probe
  parsed="$(cd "$ROOT" && uv run python harness/extract.py build "$fmt" "$sample" "$sc")" \
    || red "$fmt: parse/extract failed"
  probe="$(ffprobe -v quiet -of json -show_streams -show_format "$sample")"
  local count i name kind fpath want got
  count=$(jq ".fields | length" "$sc")
  for ((i = 0; i < count; i++)); do
    name=$(jq -r ".fields[$i].name" "$sc")
    kind=$(jq -r ".fields[$i].kind" "$sc")
    fpath=$(jq -r ".fields[$i].ffprobe_path" "$sc")
    want=$(echo "$probe" | jq -r "$fpath")
    got=$(echo "$parsed" | grep "^$name=" | cut -d= -f2-)
    if [ "$kind" = "numeric" ]; then
      [ "$got" = "$want" ] || [ "$((got))" = "$((want))" ] 2>/dev/null \
        || red "$fmt: $name differs — kaitai=$got ffprobe=$want (differential bite)"
    else
      [ "$got" = "$want" ] \
        || red "$fmt: $name differs — kaitai=$got ffprobe=$want"
    fi
    echo "  ok: $name kaitai=$got == ffprobe=$want [$kind]"
  done
  jq -r '.self_checked[]? | "  self-checked (recorded, NOT oracle-backed): " + .' "$sc"
  echo "GREEN: $fmt (independence regime: $regime)"
}

make_sidecar_variant() { # <name> <jq-filter>
  local name="$1" filter="$2"
  local out="$SELFTEST_TMP/$name.fields.json"
  jq "$filter" "$ROOT/redteam/toy.fields.json" >"$out"
  printf '%s\n' "$out"
}

expect_sidecar_rejected() { # <sidecar> <description>
  local sidecar="$1" description="$2"
  if (validate_sidecar "$sidecar") >/dev/null 2>&1; then
    echo "selftest FAIL: $description accepted"
    exit 1
  fi
}

selftest() {
  SELFTEST_TMP="$(mktemp -d)"
  case "$SELFTEST_TMP" in
    /tmp/*) ;;
    *) echo "selftest FAIL: unexpected temporary path: $SELFTEST_TMP"; exit 1 ;;
  esac
  trap 'rm -rf -- "$SELFTEST_TMP"' EXIT

  echo "selftest 1/6: toy compile + parse via pinned toolchain"
  mkdir -p "$ROOT/build"
  "$KSC" --target python --outdir "$ROOT/build" "$ROOT/redteam/toy.ksy"
  local out
  out="$(cd "$ROOT" && uv run python harness/extract.py build toy \
        redteam/toy.bin redteam/toy.fields.json)"
  echo "$out" | grep -q "^width=64$" || { echo "selftest FAIL: toy parse"; exit 1; }

  echo "selftest 2/6: red-team (b) — compile failure must bite"
  if "$KSC" --target python --outdir "$ROOT/build" "$ROOT/redteam/toy_compilefail.ksy" \
      >/dev/null 2>&1; then
    echo "selftest FAIL: broken .ksy compiled"; exit 1
  fi

  echo "selftest 3/6: red-team (c) — empty oracle map must be rejected"
  if (validate_sidecar "$ROOT/redteam/empty.fields.json") 2>/dev/null; then
    echo "selftest FAIL: empty map accepted"; exit 1
  fi

  echo "selftest 4/6: red-team (d) — label-only map must be rejected"
  if (validate_sidecar "$ROOT/redteam/labelonly.fields.json") 2>/dev/null; then
    echo "selftest FAIL: label-only map accepted"; exit 1
  fi

  echo "selftest 5/6: Tier-2 sidecar and self_checked vocabulary"
  local sc
  sc="$(make_sidecar_variant canonical \
    '.self_checked = [
      "chunk-size-sum == file length",
      "monotonic offsets",
      "declared-count == walked-count"
    ]')"
  validate_sidecar "$sc" >/dev/null

  local au_self_checked="$SELFTEST_TMP/au_self_checked.fields.json"
  jq '.self_checked = ["monotonic offsets"]' \
    "$ROOT/formats/au.fields.json" >"$au_self_checked"
  local self_checked_out
  self_checked_out="$(check_spec "$ROOT/formats/au.ksy" "$au_self_checked")"
  grep -q 'self-checked (recorded, NOT oracle-backed): monotonic offsets' \
    <<<"$self_checked_out" \
    || { echo "selftest FAIL: self_checked claim was not visibly separated"; exit 1; }

  sc="$(make_sidecar_variant unknown \
    '.self_checked = ["chunk size looks okay"]')"
  expect_sidecar_rejected "$sc" "unknown self_checked token"

  sc="$(make_sidecar_variant non_array \
    '.self_checked = "monotonic offsets"')"
  expect_sidecar_rejected "$sc" "non-array self_checked"

  sc="$(make_sidecar_variant non_string \
    '.self_checked = [42]')"
  expect_sidecar_rejected "$sc" "non-string self_checked entry"

  sc="$(make_sidecar_variant duplicate \
    '.self_checked = ["monotonic offsets", "monotonic offsets"]')"
  expect_sidecar_rejected "$sc" "duplicate self_checked entry"

  sc="$(make_sidecar_variant missing_self_checked \
    'del(.self_checked)')"
  expect_sidecar_rejected "$sc" "missing self_checked"

  sc="$(make_sidecar_variant unknown_kind \
    '.fields += [{
      "name": "mystery",
      "kaitai_path": "width",
      "ffprobe_path": ".",
      "kind": "mystery"
    }]')"
  expect_sidecar_rejected "$sc" "unknown field kind"

  sc="$(make_sidecar_variant bad_independence \
    '.independence = "generated-ish"')"
  expect_sidecar_rejected "$sc" "unknown independence regime"

  sc="$(make_sidecar_variant empty_sample '.sample = ""')"
  expect_sidecar_rejected "$sc" "empty sample path"

  sc="$(make_sidecar_variant empty_name '.fields[0].name = ""')"
  expect_sidecar_rejected "$sc" "empty field name"

  echo "selftest 6/6: red-team (a) — wrong-offset spec must go RED on the differential"
  if (check_spec "$ROOT/redteam/au_wrong_offset.ksy" \
        "$ROOT/redteam/au_wrong_offset.fields.json") >/dev/null 2>&1; then
    echo "selftest FAIL: wrong-offset spec passed the differential"; exit 1
  fi

  echo "selftest GREEN: toy machinery works and all four red-team cases bite"
}

case "${1:-}" in
  --selftest) selftest ;;
  "") echo "usage: check.sh <fmt> | --selftest" >&2; exit 2 ;;
  *) check_spec "$ROOT/formats/$1.ksy" "$ROOT/formats/$1.fields.json" ;;
esac
