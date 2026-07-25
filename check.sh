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
      (.kind == "numeric" or .kind == "label") and
      (
        (has("mediainfo_path") | not) or
        (
          .kind == "numeric" and
          (.mediainfo_path | type == "string" and length > 0)
        )
      )
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

json_scalar() { # <json-document> <jq-path>
  local document="$1" path="$2" values count value_kind value
  jq -se 'length == 1' <<<"$document" >/dev/null 2>&1 || return 2
  values="$(jq -cer "[${path}]" <<<"$document" 2>/dev/null)" || return 2
  count="$(jq -r 'length' <<<"$values")" || return 2
  [ "$count" -gt 0 ] || return 1
  [ "$count" -eq 1 ] || return 2

  value_kind="$(jq -r '.[0] | type' <<<"$values")" || return 2
  case "$value_kind" in
    null) return 1 ;;
    array|object) return 2 ;;
  esac
  value="$(jq -r '.[0] | tostring' <<<"$values")" || return 2
  [ -n "$value" ] || return 1
  printf '%s\n' "$value"
}

numeric_equal() { # <left> <right>
  jq -en --arg left "$1" --arg right "$2" '
    try (($left | tonumber) == ($right | tonumber)) catch false
  ' >/dev/null
}

resolve_mediainfo() {
  if [ "${PALIMPSEST_MEDIAINFO_BIN+x}" = x ]; then
    [ -n "$PALIMPSEST_MEDIAINFO_BIN" ] \
      && [ -x "$PALIMPSEST_MEDIAINFO_BIN" ] \
      || return 2
    printf '%s\n' "$PALIMPSEST_MEDIAINFO_BIN"
    return 0
  fi
  command -v mediainfo 2>/dev/null || return 1
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
  if ! probe="$(ffprobe -v quiet -of json -show_streams -show_format "$sample")"; then
    red "$fmt: ffprobe invocation failed"
  fi
  jq -e . <<<"$probe" >/dev/null 2>&1 \
    || red "$fmt: ffprobe emitted malformed JSON"
  local count i name kind fpath want got
  count=$(jq ".fields | length" "$sc")
  for ((i = 0; i < count; i++)); do
    name=$(jq -r ".fields[$i].name" "$sc")
    kind=$(jq -r ".fields[$i].kind" "$sc")
    fpath=$(jq -r ".fields[$i].ffprobe_path" "$sc")
    if ! want="$(json_scalar "$probe" "$fpath")"; then
      red "$fmt: $name has no single usable FFprobe oracle value"
    fi
    got=$(echo "$parsed" | grep "^$name=" | cut -d= -f2-)
    if [ "$kind" = "numeric" ]; then
      numeric_equal "$got" "$want" \
        || red "$fmt: $name differs — kaitai=$got ffprobe=$want (differential bite)"
    else
      [ "$got" = "$want" ] \
        || red "$fmt: $name differs — kaitai=$got ffprobe=$want"
    fi
    echo "  ok: $name kaitai=$got == ffprobe=$want [$kind]"
  done

  local mediainfo_total
  mediainfo_total="$(jq '[.fields[] | select(has("mediainfo_path"))] | length' "$sc")"
  if [ "$mediainfo_total" -gt 0 ]; then
    local mediainfo_bin mediainfo_status
    if mediainfo_bin="$(resolve_mediainfo)"; then
      local mediainfo_probe
      if ! mediainfo_probe="$("$mediainfo_bin" \
          --Output=JSON --File_TestContinuousFileNames=0 "$sample")"; then
        red "$fmt: installed MediaInfo invocation failed"
      fi
      jq -e . <<<"$mediainfo_probe" >/dev/null 2>&1 \
        || red "$fmt: installed MediaInfo emitted malformed JSON"

      local mediainfo_checked=0 mediainfo_skipped=0 mediainfo_path mediainfo_want
      for ((i = 0; i < count; i++)); do
        mediainfo_path="$(jq -r ".fields[$i].mediainfo_path // empty" "$sc")"
        [ -n "$mediainfo_path" ] || continue
        name="$(jq -r ".fields[$i].name" "$sc")"
        got="$(grep "^$name=" <<<"$parsed" | cut -d= -f2-)"

        if mediainfo_want="$(json_scalar "$mediainfo_probe" "$mediainfo_path")"; then
          numeric_equal "$got" "$mediainfo_want" \
            || red "$fmt: $name differs — kaitai=$got mediainfo=$mediainfo_want (second-oracle bite)"
          echo "  ok: $name kaitai=$got == mediainfo=$mediainfo_want [second oracle]"
          mediainfo_checked=$((mediainfo_checked + 1))
        else
          mediainfo_status=$?
          if [ "$mediainfo_status" -eq 1 ]; then
            echo "  mediainfo: $name unavailable (mapped field skipped)"
            mediainfo_skipped=$((mediainfo_skipped + 1))
          else
            red "$fmt: $name MediaInfo path did not resolve to one scalar"
          fi
        fi
      done
      echo "  mediainfo: checked $mediainfo_checked, skipped $mediainfo_skipped of $mediainfo_total mapped field(s)"
    else
      mediainfo_status=$?
      if [ "$mediainfo_status" -eq 1 ]; then
        echo "  mediainfo: unavailable; skipped $mediainfo_total mapped field(s)"
      else
        red "$fmt: PALIMPSEST_MEDIAINFO_BIN is not an executable file"
      fi
    fi
  fi
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

expect_json_scalar_status() { # <status> <json-document> <jq-path> <description>
  local expected="$1" document="$2" path="$3" description="$4" actual=0
  json_scalar "$document" "$path" >/dev/null 2>&1 || actual=$?
  [ "$actual" -eq "$expected" ] || {
    echo "selftest FAIL: $description returned status $actual, expected $expected"
    exit 1
  }
}

selftest() {
  SELFTEST_TMP="$(mktemp -d)"
  case "$SELFTEST_TMP" in
    /tmp/*) ;;
    *) echo "selftest FAIL: unexpected temporary path: $SELFTEST_TMP"; exit 1 ;;
  esac
  trap 'rm -rf -- "$SELFTEST_TMP"' EXIT

  echo "selftest 1/9: toy compile + parse via pinned toolchain"
  mkdir -p "$ROOT/build"
  "$KSC" --target python --outdir "$ROOT/build" "$ROOT/redteam/toy.ksy"
  local out
  out="$(cd "$ROOT" && uv run python harness/extract.py build toy \
        redteam/toy.bin redteam/toy.fields.json)"
  echo "$out" | grep -q "^width=64$" || { echo "selftest FAIL: toy parse"; exit 1; }

  echo "selftest 2/9: red-team (b) — compile failure must bite"
  if "$KSC" --target python --outdir "$ROOT/build" "$ROOT/redteam/toy_compilefail.ksy" \
      >/dev/null 2>&1; then
    echo "selftest FAIL: broken .ksy compiled"; exit 1
  fi

  echo "selftest 3/9: red-team (c) — empty oracle map must be rejected"
  if (validate_sidecar "$ROOT/redteam/empty.fields.json") 2>/dev/null; then
    echo "selftest FAIL: empty map accepted"; exit 1
  fi

  echo "selftest 4/9: red-team (d) — label-only map must be rejected"
  if (validate_sidecar "$ROOT/redteam/labelonly.fields.json") 2>/dev/null; then
    echo "selftest FAIL: label-only map accepted"; exit 1
  fi

  echo "selftest 5/9: Tier-2 sidecar and self_checked vocabulary"
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

  echo "selftest 6/9: red-team (a) — wrong-offset spec must go RED on the differential"
  if (check_spec "$ROOT/redteam/au_wrong_offset.ksy" \
        "$ROOT/redteam/au_wrong_offset.fields.json") >/dev/null 2>&1; then
    echo "selftest FAIL: wrong-offset spec passed the differential"; exit 1
  fi

  echo "selftest 7/9: undecidable oracle values must not pass"
  if (check_spec "$ROOT/redteam/au_null_oracle.ksy" \
        "$ROOT/redteam/au_null_oracle.fields.json") >/dev/null 2>&1; then
    echo "selftest FAIL: missing FFprobe value passed as literal null"
    exit 1
  fi

  local scalar
  scalar="$(json_scalar '{"value":"8000"}' '.value')" \
    || { echo "selftest FAIL: usable scalar rejected"; exit 1; }
  [ "$scalar" = "8000" ] \
    || { echo "selftest FAIL: scalar changed"; exit 1; }
  if json_scalar '{}' '.missing' >/dev/null 2>&1; then
    echo "selftest FAIL: missing scalar accepted"; exit 1
  fi
  if json_scalar '{"value":null}' '.value' >/dev/null 2>&1; then
    echo "selftest FAIL: null scalar accepted"; exit 1
  fi
  if json_scalar '{"value":[]}' '.value' >/dev/null 2>&1; then
    echo "selftest FAIL: array accepted as scalar"; exit 1
  fi
  if json_scalar '{"values":[1,2]}' '.values[]' >/dev/null 2>&1; then
    echo "selftest FAIL: multiple values accepted as scalar"; exit 1
  fi
  if json_scalar '{broken' '.value' >/dev/null 2>&1; then
    echo "selftest FAIL: malformed JSON accepted"; exit 1
  fi
  expect_json_scalar_status 1 '{}' '.missing' "absent scalar"
  expect_json_scalar_status 2 '{"value":[]}' '.value' "non-scalar value"
  expect_json_scalar_status 2 '' '.value' "empty JSON document stream"
  expect_json_scalar_status 2 $'{"value":1}\n{"value":2}' '.value' \
    "multiple top-level JSON documents"
  expect_json_scalar_status 2 '{broken' '.value' "malformed JSON document"
  numeric_equal "8000" "8000.0" \
    || { echo "selftest FAIL: numeric normalization rejected equality"; exit 1; }
  if numeric_equal "8000" "7999"; then
    echo "selftest FAIL: unequal numerics accepted"; exit 1
  fi

  echo "selftest 8/9: optional MediaInfo cross-checking"
  sc="$(make_sidecar_variant label_mediainfo '
    .fields += [{
      "name": "label_with_second_oracle",
      "kaitai_path": "width",
      "ffprobe_path": ".",
      "mediainfo_path": ".media.track[0].Format",
      "kind": "label"
    }]
  ')"
  expect_sidecar_rejected "$sc" "MediaInfo mapping on label field"

  sc="$(make_sidecar_variant empty_mediainfo_path \
    '.fields[0].mediainfo_path = ""')"
  expect_sidecar_rejected "$sc" "empty MediaInfo path"

  sc="$(make_sidecar_variant non_string_mediainfo_path \
    '.fields[0].mediainfo_path = 42')"
  expect_sidecar_rejected "$sc" "non-string MediaInfo path"

  local mi_sc="$SELFTEST_TMP/au_mediainfo.fields.json"
  jq '
    (.fields[] | select(.name == "sample_rate")).mediainfo_path =
      ".media.track | map(select(.\"@type\" == \"Audio\"))[0].SamplingRate" |
    (.fields[] | select(.name == "channels")).mediainfo_path =
      ".media.track | map(select(.\"@type\" == \"Audio\"))[0].Channels"
  ' "$ROOT/formats/au.fields.json" >"$mi_sc"

  if (PALIMPSEST_FAKE_MEDIAINFO_MODE=mismatch \
      PALIMPSEST_MEDIAINFO_BIN="$ROOT/redteam/fake_mediainfo" \
      check_spec "$ROOT/formats/au.ksy" "$mi_sc") \
      >/dev/null 2>&1; then
    echo "selftest FAIL: MediaInfo mismatch passed"
    exit 1
  fi

  local mi_out mi_count_file="$SELFTEST_TMP/mediainfo-invocations" mi_count
  : >"$mi_count_file"
  if ! mi_out="$(PALIMPSEST_FAKE_MEDIAINFO_MODE=match \
      PALIMPSEST_FAKE_MEDIAINFO_COUNT_FILE="$mi_count_file" \
      PALIMPSEST_MEDIAINFO_BIN="$ROOT/redteam/fake_mediainfo" \
      check_spec "$ROOT/formats/au.ksy" "$mi_sc" 2>&1)"; then
    echo "selftest FAIL: matching MediaInfo result failed"
    exit 1
  fi
  grep -q 'mediainfo: checked 2, skipped 0 of 2 mapped field(s)' <<<"$mi_out" \
    || { echo "selftest FAIL: matching MediaInfo summary missing"; exit 1; }
  mi_count="$(wc -l <"$mi_count_file")"
  [ "$mi_count" -eq 1 ] \
    || { echo "selftest FAIL: MediaInfo invoked $mi_count times, expected 1"; exit 1; }

  if ! mi_out="$(PALIMPSEST_FAKE_MEDIAINFO_MODE=missing \
      PALIMPSEST_MEDIAINFO_BIN="$ROOT/redteam/fake_mediainfo" \
      check_spec "$ROOT/formats/au.ksy" "$mi_sc" 2>&1)"; then
    echo "selftest FAIL: absent mapped MediaInfo field was not best-effort"
    exit 1
  fi
  grep -q 'mediainfo: channels unavailable (mapped field skipped)' <<<"$mi_out" \
    || { echo "selftest FAIL: missing-field skip was not visible"; exit 1; }
  grep -q 'mediainfo: checked 1, skipped 1 of 2 mapped field(s)' <<<"$mi_out" \
    || { echo "selftest FAIL: partial MediaInfo summary missing"; exit 1; }

  local mode
  for mode in malformed failure nonscalar; do
    if (PALIMPSEST_FAKE_MEDIAINFO_MODE="$mode" \
        PALIMPSEST_MEDIAINFO_BIN="$ROOT/redteam/fake_mediainfo" \
        check_spec "$ROOT/formats/au.ksy" "$mi_sc") \
        >/dev/null 2>&1; then
      echo "selftest FAIL: MediaInfo $mode result passed"
      exit 1
    fi
  done

  if (PALIMPSEST_FAKE_MEDIAINFO_MODE=multiple \
      PALIMPSEST_MEDIAINFO_BIN="$ROOT/redteam/fake_mediainfo" \
      check_spec "$ROOT/formats/au.ksy" "$mi_sc") \
      >/dev/null 2>&1; then
    echo "selftest FAIL: multiple top-level MediaInfo JSON documents passed"
    exit 1
  fi

  if (PALIMPSEST_MEDIAINFO_BIN="$ROOT/redteam/not-an-executable" \
      check_spec "$ROOT/formats/au.ksy" "$mi_sc") \
      >/dev/null 2>&1; then
    echo "selftest FAIL: unusable MediaInfo override passed"
    exit 1
  fi

  local absent_status=0
  PATH=/nonexistent resolve_mediainfo >/dev/null 2>&1 || absent_status=$?
  [ "$absent_status" -eq 1 ] \
    || { echo "selftest FAIL: absent MediaInfo was not optional"; exit 1; }

  echo "selftest 9/9: malformed-input hardening must reject bad containers"
  # Compile the hardened specs (formats used by the fixtures below).
  "$KSC" --target python --outdir "$ROOT/build" "$ROOT/formats/aiff.ksy" \
    || { echo "selftest FAIL: aiff compile for malformed-input"; exit 1; }
  "$KSC" --target python --outdir "$ROOT/build" "$ROOT/formats/au.ksy" \
    || { echo "selftest FAIL: au compile for malformed-input"; exit 1; }

  # Undersized AIFF FORM size field (20 < min 46) must fail validation.
  if (cd "$ROOT" && uv run python harness/extract.py build aiff \
        redteam/aiff_undersized_form.bin formats/aiff.fields.json) \
      >/dev/null 2>&1; then
    echo "selftest FAIL: undersized AIFF FORM accepted"
    exit 1
  fi

  # FORM large enough for COMM alone but too small for COMM+SSND (40 < 46).
  if (cd "$ROOT" && uv run python harness/extract.py build aiff \
        redteam/aiff_form_too_small_for_ssnd.bin formats/aiff.fields.json) \
      >/dev/null 2>&1; then
    echo "selftest FAIL: AIFF FORM too small for SSND walk accepted"
    exit 1
  fi

  # AU data_offset below the 24-byte fixed header must fail validation.
  if (cd "$ROOT" && uv run python harness/extract.py build au \
        redteam/au_short_offset.bin formats/au.fields.json) \
      >/dev/null 2>&1; then
    echo "selftest FAIL: AU short data_offset accepted"
    exit 1
  fi

  echo "selftest GREEN: toy machinery, sidecar boundary, both oracle paths, red-team cases, and malformed-input hardening hold"
}

case "${1:-}" in
  --selftest) selftest ;;
  "") echo "usage: check.sh <fmt> | --selftest" >&2; exit 2 ;;
  *) check_spec "$ROOT/formats/$1.ksy" "$ROOT/formats/$1.fields.json" ;;
esac
