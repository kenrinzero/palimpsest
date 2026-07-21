# Palimpsest Tier-2 Harness Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enforce Palimpsest's closed `self_checked` vocabulary, reject undecidable oracle claims, and add optional per-field MediaInfo cross-checks without making MediaInfo a dependency.

**Architecture:** Keep `check.sh` as the single gate and keep format-specific oracle paths in each `formats/*.fields.json` sidecar. Add strict sidecar validation and shared scalar/numeric helpers first, then layer one optional MediaInfo invocation over already-green Kaitai↔FFprobe comparisons. Exercise all new behavior through the existing `./check.sh --selftest` entry point with one deliberately exploitable null-oracle fixture and one deterministic fake MediaInfo executable.

**Tech Stack:** Bash 5, jq 1.6, pinned FFprobe 6.1.1, pinned Kaitai Struct compiler 0.11, Python/Kaitai runtime through `uv`, optional MediaInfo CLI JSON.

## Global Constraints

- Preserve `redteam/au_wrong_offset.ksy` exactly; it is deliberately wrong and must remain red.
- Run `./check.sh --selftest` after every harness change.
- Keep `self_checked` recorded and visibly `NOT oracle-backed`; it never satisfies the numeric oracle floor.
- Accept only these exact, case-sensitive self-check kinds: `chunk-size-sum == file length`, `monotonic offsets`, `declared-count == walked-count`.
- MediaInfo is optional. An absent binary or absent mapped field skips visibly; a present mismatch, unusable override, non-zero invocation, malformed JSON, or ambiguous/non-scalar mapped value is red.
- Do not change format parsers, samples, toolchain pins, or independence tags.
- Add MediaInfo paths only for AU sample rate/channels, AIFF channels/bit depth, and DPX width/height.
- Leave AIFF sample frames, VOC, RoQ, labels, and every third-party unit unmapped.
- Resolve an explicit override from `PALIMPSEST_MEDIAINFO_BIN`; otherwise use `mediainfo` from `PATH`.
- Invoke MediaInfo once per mapped sample with `--Output=JSON --File_TestContinuousFileNames=0`.
- Retain the sidecar's declared independence regime; report MediaInfo checked/skipped counts separately.
- Use `apply_patch` for repository file edits and preserve unrelated work.

## File map

- Modify `check.sh`: sidecar schema validation, JSON scalar handling, numeric comparison, MediaInfo resolution/invocation, and all selftests.
- Create `redteam/au_null_oracle.ksy`: correct AU numeric parsing plus a deliberate string `"null"` instance that demonstrates the old null-oracle hole.
- Create `redteam/au_null_oracle.fields.json`: one real numeric FFprobe field plus one missing label path that the old gate incorrectly credits.
- Create `redteam/fake_mediainfo`: deterministic MediaInfo-compatible JSON producer for integration selftests.
- Modify `formats/au.fields.json`: add two numeric MediaInfo paths.
- Modify `formats/aiff.fields.json`: add two numeric MediaInfo paths while leaving sample frames unmapped.
- Modify `formats/dpx.fields.json`: add two numeric MediaInfo paths.
- Modify `DESIGN.md`: settle the Tier-2 sidecar and optional-oracle contract.
- Modify `BACKLOG.md`: mark Tier 2 complete.
- Modify `README.md`: describe strict self-check claims and optional second-oracle output.
- Modify `docs/superpowers/specs/2026-07-21-harness-hardening-design.md`: mark the approved design implemented after all gates pass.

---

### Task 1: Enforce the sidecar and `self_checked` contract

**Files:**
- Modify: `check.sh:17-25` (`validate_sidecar`)
- Modify: `check.sh:65-97` (`selftest`)

**Interfaces:**
- Consumes: existing `validate_sidecar <sidecar-path>` call sites.
- Produces: the same zero/non-zero validation interface, now enforcing required property types, exact field kinds, exact independence tags, a numeric floor, and the closed self-check vocabulary.

- [ ] **Step 1: Add selftest-side sidecar variant helpers and failing contract cases**

Add these helpers immediately before `selftest()`:

```bash
make_sidecar_variant() { # <name> <jq-filter>
  local name="$1" filter="$2" out="$SELFTEST_TMP/$name.fields.json"
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
```

At the start of `selftest()`, create one guarded temporary directory:

```bash
  SELFTEST_TMP="$(mktemp -d)"
  case "$SELFTEST_TMP" in
    /tmp/*) ;;
    *) echo "selftest FAIL: unexpected temporary path: $SELFTEST_TMP"; exit 1 ;;
  esac
  trap 'rm -rf -- "$SELFTEST_TMP"' EXIT
```

Change the existing progress labels from `/5` to `/6`, insert the following section before the wrong-offset case, and renumber the wrong-offset case to `6/6`:

```bash
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
```

- [ ] **Step 2: Run selftest and confirm the vocabulary test is red**

Run:

```bash
./check.sh --selftest
```

Expected: non-zero with `selftest FAIL: unknown self_checked token accepted`. The first four existing sections must run as before up to this new failure; the wrong-offset section follows it.

- [ ] **Step 3: Replace `validate_sidecar` with the strict minimal implementation**

Use this implementation:

```bash
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
```

- [ ] **Step 4: Re-run selftest and confirm all six sections are green**

Run:

```bash
./check.sh --selftest
```

Expected: exit 0, `selftest GREEN`, and the original four red-team cases still bite.

- [ ] **Step 5: Commit the strict sidecar contract**

```bash
git add check.sh
git commit -m "Enforce Palimpsest sidecar vocabulary"
```

---

### Task 2: Reject null, empty, malformed, and ambiguous oracle values

**Files:**
- Create: `redteam/au_null_oracle.ksy`
- Create: `redteam/au_null_oracle.fields.json`
- Modify: `check.sh` (JSON scalar helpers, numeric comparison, FFprobe extraction, selftest)

**Interfaces:**
- Produces: `json_scalar <json-document> <jq-path>`, printing one usable scalar and returning 0; returning 1 for absent/null/empty values; returning 2 for malformed JSON, multiple results, arrays, or objects.
- Produces: `numeric_equal <left> <right>`, returning 0 when jq numeric conversion makes the values equal and non-zero otherwise.
- Changes: every FFprobe mapping must resolve to exactly one usable scalar before comparison.

- [ ] **Step 1: Add the exploitable null-oracle fixture**

Create `redteam/au_null_oracle.ksy`:

```yaml
meta:
  id: au_null_oracle
  file-extension: au
  endian: be
seq:
  - id: magic
    contents: [0x2e, 0x73, 0x6e, 0x64]
  - id: data_offset
    type: u4
  - id: data_size
    type: u4
  - id: encoding
    type: u4
  - id: sample_rate
    type: u4
  - id: channels
    type: u4
instances:
  null_label:
    value: '"null"'
```

Create `redteam/au_null_oracle.fields.json`:

```json
{
  "sample": "samples/au/sine.au",
  "independence": "self-generated",
  "fields": [
    {
      "name": "sample_rate",
      "kaitai_path": "sample_rate",
      "ffprobe_path": ".streams[0].sample_rate",
      "kind": "numeric"
    },
    {
      "name": "null_value",
      "kaitai_path": "null_label",
      "ffprobe_path": ".streams[0].missing",
      "kind": "label"
    }
  ],
  "self_checked": []
}
```

- [ ] **Step 2: Add failing scalar and null-oracle selftests**

Change all progress denominators to `/7`. After the wrong-offset case, add:

```bash
  echo "selftest 7/7: undecidable oracle values must not pass"
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
  numeric_equal "8000" "8000.0" \
    || { echo "selftest FAIL: numeric normalization rejected equality"; exit 1; }
  if numeric_equal "8000" "7999"; then
    echo "selftest FAIL: unequal numerics accepted"; exit 1
  fi
```

- [ ] **Step 3: Run selftest and observe the old null/null comparison pass incorrectly**

Run:

```bash
./check.sh --selftest
```

Expected: non-zero with `selftest FAIL: missing FFprobe value passed as literal null`. This proves the fixture reaches the old vulnerability rather than merely failing to compile.

- [ ] **Step 4: Add scalar helpers and require them in the FFprobe loop**

Add these functions after `validate_sidecar`:

```bash
json_scalar() { # <json-document> <jq-path>
  local document="$1" path="$2" values count value_kind value
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
```

Replace the unguarded FFprobe assignment with:

```bash
  if ! probe="$(ffprobe -v quiet -of json -show_streams -show_format "$sample")"; then
    red "$fmt: ffprobe invocation failed"
  fi
  jq -e . <<<"$probe" >/dev/null 2>&1 \
    || red "$fmt: ffprobe emitted malformed JSON"
```

Replace `want=$(echo "$probe" | jq -r "$fpath")` with:

```bash
    if ! want="$(json_scalar "$probe" "$fpath")"; then
      red "$fmt: $name has no single usable FFprobe oracle value"
    fi
```

Replace shell arithmetic numeric comparison with:

```bash
    if [ "$kind" = "numeric" ]; then
      numeric_equal "$got" "$want" \
        || red "$fmt: $name differs — kaitai=$got ffprobe=$want (differential bite)"
    else
      [ "$got" = "$want" ] \
        || red "$fmt: $name differs — kaitai=$got ffprobe=$want"
    fi
```

- [ ] **Step 5: Run selftest and every currently implemented gate**

Run:

```bash
./check.sh --selftest
for fmt in au voc roq flic smk bink wsvqa ipmovie aiff dpx; do
  ./check.sh "$fmt"
done
```

Expected: selftest exit 0; ten `GREEN: <fmt>` lines; the new null-oracle fixture and original wrong-offset fixture both remain red internally.

- [ ] **Step 6: Commit scalar oracle hardening**

```bash
git add check.sh redteam/au_null_oracle.ksy redteam/au_null_oracle.fields.json
git commit -m "Reject undecidable Palimpsest oracle values"
```

---

### Task 3: Add optional per-field MediaInfo cross-checking

**Files:**
- Create: `redteam/fake_mediainfo`
- Modify: `check.sh`
- Modify: `formats/au.fields.json`
- Modify: `formats/aiff.fields.json`
- Modify: `formats/dpx.fields.json`

**Interfaces:**
- Produces: `resolve_mediainfo`, printing an executable and returning 0; returning 1 when no default binary exists; returning 2 for a set but unusable `PALIMPSEST_MEDIAINFO_BIN`.
- Extends: numeric sidecar fields may carry one non-empty `mediainfo_path`; label fields may not.
- Changes: `check_spec` invokes MediaInfo at most once only when mappings exist, then reports exact checked/skipped counts.

- [ ] **Step 1: Add the fake MediaInfo test executable**

Create `redteam/fake_mediainfo` and make it executable:

```bash
#!/usr/bin/env bash
set -euo pipefail

[ "${1:-}" = "--Output=JSON" ] || exit 64
[ "${2:-}" = "--File_TestContinuousFileNames=0" ] || exit 64
[ "$#" -eq 3 ] || exit 64

case "${PALIMPSEST_FAKE_MEDIAINFO_MODE:-match}" in
  match)
    printf '%s\n' '{"media":{"track":[{"@type":"Audio","SamplingRate":"8000","Channels":"1"}]}}'
    ;;
  missing)
    printf '%s\n' '{"media":{"track":[{"@type":"Audio","SamplingRate":"8000"}]}}'
    ;;
  mismatch)
    printf '%s\n' '{"media":{"track":[{"@type":"Audio","SamplingRate":"7999","Channels":"1"}]}}'
    ;;
  malformed)
    printf '%s\n' '{broken'
    ;;
  failure)
    exit 23
    ;;
  nonscalar)
    printf '%s\n' '{"media":{"track":[{"@type":"Audio","SamplingRate":{"raw":"8000"},"Channels":"1"}]}}'
    ;;
  *)
    exit 65
    ;;
esac
```

Run:

```bash
chmod +x redteam/fake_mediainfo
```

- [ ] **Step 2: Add failing MediaInfo schema and integration selftests**

Change all progress denominators to `/8`. After the undecidable-oracle section, add:

```bash
  echo "selftest 8/8: optional MediaInfo cross-checking"
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

  local mi_out
  if ! mi_out="$(PALIMPSEST_FAKE_MEDIAINFO_MODE=match \
      PALIMPSEST_MEDIAINFO_BIN="$ROOT/redteam/fake_mediainfo" \
      check_spec "$ROOT/formats/au.ksy" "$mi_sc" 2>&1)"; then
    echo "selftest FAIL: matching MediaInfo result failed"
    exit 1
  fi
  grep -q 'mediainfo: checked 2, skipped 0 of 2 mapped field(s)' <<<"$mi_out" \
    || { echo "selftest FAIL: matching MediaInfo summary missing"; exit 1; }

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
```

- [ ] **Step 3: Run selftest and confirm the unmapped schema is accepted incorrectly**

Run:

```bash
./check.sh --selftest
```

Expected first red: `selftest FAIL: MediaInfo mapping on label field accepted`.

- [ ] **Step 4: Extend field validation for `mediainfo_path` and observe the mismatch test turn red next**

Extend the `all(.fields[]; ...)` predicate in `validate_sidecar` with:

```jq
and (
  (has("mediainfo_path") | not) or
  (
    .kind == "numeric" and
    (.mediainfo_path | type == "string" and length > 0)
  )
)
```

Run:

```bash
./check.sh --selftest
```

Expected next red: `selftest FAIL: MediaInfo mismatch passed`. That confirms the production gate still ignores the fake second oracle.

- [ ] **Step 5: Implement resolver and one-pass MediaInfo comparison**

Add after `numeric_equal`:

```bash
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
```

After the FFprobe field loop and before printing `self_checked`, add:

```bash
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
```

Change the final selftest summary to:

```bash
  echo "selftest GREEN: toy machinery, sidecar boundary, both oracle paths, and all red-team cases hold"
```

- [ ] **Step 6: Run syntax checks and the complete selftest**

Run:

```bash
bash -n check.sh redteam/fake_mediainfo
./check.sh --selftest
```

Expected: syntax checks exit 0; all eight selftest sections pass; fake match reports 2/2, fake missing reports 1/2, and mismatch/malformed/failure/non-scalar/unusable-override cases all bite.

- [ ] **Step 7: Add the proven real mappings and run all ten gates**

Add these exact keys to the existing numeric field objects:

```jsonc
// formats/au.fields.json
{ "name": "sample_rate", "kaitai_path": "sample_rate", "ffprobe_path": ".streams[0].sample_rate", "mediainfo_path": ".media.track | map(select(.\"@type\" == \"Audio\"))[0].SamplingRate", "kind": "numeric" },
{ "name": "channels", "kaitai_path": "channels", "ffprobe_path": ".streams[0].channels", "mediainfo_path": ".media.track | map(select(.\"@type\" == \"Audio\"))[0].Channels", "kind": "numeric" }

// formats/aiff.fields.json
{ "name": "channels", "kaitai_path": "common.num_channels", "ffprobe_path": ".streams[0].channels", "mediainfo_path": ".media.track | map(select(.\"@type\" == \"Audio\"))[0].Channels", "kind": "numeric" },
{ "name": "bits_per_sample", "kaitai_path": "common.sample_size", "ffprobe_path": ".streams[0].bits_per_sample", "mediainfo_path": ".media.track | map(select(.\"@type\" == \"Audio\"))[0].BitDepth", "kind": "numeric" }

// formats/dpx.fields.json
{ "name": "width", "kaitai_path": "body.image_information.pixels_per_line", "ffprobe_path": ".streams[0].width", "mediainfo_path": ".media.track | map(select(.\"@type\" == \"Image\"))[0].Width", "kind": "numeric" },
{ "name": "height", "kaitai_path": "body.image_information.lines_per_image_element", "ffprobe_path": ".streams[0].height", "mediainfo_path": ".media.track | map(select(.\"@type\" == \"Image\"))[0].Height", "kind": "numeric" }
```

Do not add `mediainfo_path` to any other field.

Run:

```bash
unset PALIMPSEST_MEDIAINFO_BIN PALIMPSEST_FAKE_MEDIAINFO_MODE
for fmt in au voc roq flic smk bink wsvqa ipmovie aiff dpx; do
  ./check.sh "$fmt"
done
```

Expected: ten green gates. AU, AIFF, and DPX explicitly report their mapped MediaInfo fields skipped because the binary is absent; the other seven do not invoke or mention MediaInfo.

- [ ] **Step 8: Commit the optional second oracle**

```bash
git add check.sh redteam/fake_mediainfo \
  formats/au.fields.json formats/aiff.fields.json formats/dpx.fields.json
git commit -m "Add optional MediaInfo cross-checks"
```

---

### Task 4: Settle documentation and perform the release proof

**Files:**
- Modify: `DESIGN.md`
- Modify: `BACKLOG.md`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-07-21-harness-hardening-design.md`

**Interfaces:**
- Consumes: the green Tier-2 harness from Tasks 1–3.
- Produces: durable contract documentation that exactly matches executable behavior and a clean, fully re-proven repository.

- [ ] **Step 1: Update the frozen design contract with the landed Tier-2 extension**

In `DESIGN.md`, extend the sidecar example's numeric field with:

```json
"mediainfo_path": ".media.track | map(select(.\"@type\" == \"Audio\"))[0].SamplingRate"
```

Immediately after the schema example, add:

```markdown
Tier-2 hardening (settled 2026-07-21): `self_checked` is a required array
of unique strings from exactly `chunk-size-sum == file length`,
`monotonic offsets`, and `declared-count == walked-count`. These entries
remain recorded claims and never count as oracle-backed. Sidecar field kinds
are closed to `numeric` and `label`, independence tags are closed to the two
regimes above, and every FFprobe path must resolve to one non-null scalar.

A numeric field may opt into the best-effort second oracle with a non-empty
`mediainfo_path`. If MediaInfo is absent, or valid output omits that field,
the mapping is visibly skipped. A present disagreement, unusable configured
binary, command failure, malformed JSON, or non-scalar result turns the gate
red. The final independence tag is unchanged; output reports exact
MediaInfo checked/skipped counts.
```

Replace the opening paragraph of DESIGN §3 with:

```markdown
sidecar sanity (complete schema, canonical self-check vocabulary, non-empty
numeric oracle floor) → compile gate (`toolchain/ksc --target python`) →
parse the sample with the compiled parser (`harness/extract.py`) → pull each
required field from `ffprobe -of json` as one non-null scalar →
field-by-field compare → optionally run MediaInfo once and compare every
available mapped numeric field → report self-checked claims separately →
non-zero exit on any required-oracle or available-second-oracle mismatch.
```

Replace DESIGN §3's selftest paragraph with:

```markdown
`check.sh --selftest` drives the original four red-team cases, the toy
compile/parse smoke, strict sidecar-vocabulary cases, the null-oracle
anti-model, and deterministic optional-MediaInfo match/skip/failure cases.
Run it after any harness change.
```

Append this paragraph after the four-case list in DESIGN §5:

```markdown
Tier-2 adds boundary fixtures without weakening or renumbering these original
four cases: malformed sidecars and unknown self-check claims are rejected, a
missing FFprobe path cannot pass as the literal label `null`, and fake
MediaInfo output proves matching, partial-support, mismatch, malformed,
non-scalar, command-failure, and bad-override behavior.
```

- [ ] **Step 2: Mark the backlog and user-facing status complete**

Replace the Tier-2 heading and paragraph in `BACKLOG.md` with:

```markdown
## Tier 2 — oracle/self-checked boundary hardening — DONE 2026-07-21

`self_checked` now accepts only the three canonical bounded consistency
claims and never contributes oracle credit. Sidecars reject unknown kinds,
regimes, and unusable oracle paths. AU, AIFF, and DPX carry proven numeric
MediaInfo mappings that run when the optional CLI is installed; missing
support skips visibly, while usable disagreements and broken output go red.
```

Add this paragraph to `README.md` after the green-definition paragraph:

```markdown
Sidecars may also declare canonical `self_checked` consistency claims, always
reported as recorded and not oracle-backed. Selected numeric fields in the
self-generated AU, AIFF, and DPX units opt into MediaInfo as a best-effort
second oracle. MediaInfo is not required; each run reports exactly which
mapped fields were checked or skipped.
```

Change the design spec status line to:

```markdown
**Status:** Implemented
```

- [ ] **Step 3: Run documentation and shell sanity checks**

Run:

```bash
git diff --check
bash -n check.sh redteam/fake_mediainfo
rg -n 'Tier 2|self_checked|mediainfo_path|MediaInfo' \
  DESIGN.md BACKLOG.md README.md \
  docs/superpowers/specs/2026-07-21-harness-hardening-design.md
```

Expected: no whitespace or shell syntax errors; every contract term is present in the intended durable documents.

- [ ] **Step 4: Run the final post-documentation verification matrix**

Run:

```bash
./check.sh --selftest
for fmt in au voc roq flic smk bink wsvqa ipmovie aiff dpx; do
  ./check.sh "$fmt"
done
git diff --check
git status --short
```

Expected: selftest green; ten format gates green; no diff-check errors; only the four intended documentation files are modified.

- [ ] **Step 5: Commit documentation**

```bash
git add DESIGN.md BACKLOG.md README.md \
  docs/superpowers/specs/2026-07-21-harness-hardening-design.md
git commit -m "Document Tier 2 harness guarantees"
```

- [ ] **Step 6: Verify the committed tree**

Run:

```bash
./check.sh --selftest
for fmt in au voc roq flic smk bink wsvqa ipmovie aiff dpx; do
  ./check.sh "$fmt"
done
git status --short --branch
git log --oneline -6
```

Expected: all gates remain green from committed `HEAD`; `git status` shows only `## main`; the four implementation commits follow this plan commit, with design commit `24229a9` immediately before it.

---

## Execution completion gate

After Task 4, invoke `superpowers:requesting-code-review` for an independent review of the complete diff from `24229a9` through `HEAD`. Address any validated Critical or Important finding test-first, then invoke `superpowers:verification-before-completion` and repeat the committed-tree matrix. Only after both gates pass should the Atelier brief/log/week-log/INDEX be updated and session #85 clocked out.
