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
  local sc="$1"
  [ -f "$sc" ] || red "missing sidecar $sc"
  local n num
  n=$(jq ".fields | length" "$sc")
  [ "$n" -gt 0 ] || red "$(basename "$sc"): empty oracle field map (red-team case c)"
  num=$(jq "[.fields[] | select(.kind == \"numeric\")] | length" "$sc")
  [ "$num" -gt 0 ] || red "$(basename "$sc"): label-only field map — magic re-detection is not parsing (red-team case d)"
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

selftest() {
  echo "selftest 1/5: toy compile + parse via pinned toolchain"
  mkdir -p "$ROOT/build"
  "$KSC" --target python --outdir "$ROOT/build" "$ROOT/redteam/toy.ksy"
  local out
  out="$(cd "$ROOT" && uv run python harness/extract.py build toy \
        redteam/toy.bin redteam/toy.fields.json)"
  echo "$out" | grep -q "^width=64$" || { echo "selftest FAIL: toy parse"; exit 1; }

  echo "selftest 2/5: red-team (b) — compile failure must bite"
  if "$KSC" --target python --outdir "$ROOT/build" "$ROOT/redteam/toy_compilefail.ksy" \
      >/dev/null 2>&1; then
    echo "selftest FAIL: broken .ksy compiled"; exit 1
  fi

  echo "selftest 3/5: red-team (c) — empty oracle map must be rejected"
  if (validate_sidecar "$ROOT/redteam/empty.fields.json") 2>/dev/null; then
    echo "selftest FAIL: empty map accepted"; exit 1
  fi

  echo "selftest 4/5: red-team (d) — label-only map must be rejected"
  if (validate_sidecar "$ROOT/redteam/labelonly.fields.json") 2>/dev/null; then
    echo "selftest FAIL: label-only map accepted"; exit 1
  fi

  echo "selftest 5/5: red-team (a) — wrong-offset spec must go RED on the differential"
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
