# Palimpsest Tier-2 Harness Hardening Design

**Date:** 2026-07-21  
**Status:** Implemented
**Scope:** `check.sh`, its selftest fixtures, the field sidecars, and the
documentation that defines their contract

## Context

Before this unit, Palimpsest's differential gate already required every
format to expose at least one numeric, offset-sensitive field that agreed
between its compiled Kaitai parser and FFprobe. Two planned Tier-2 protections
were absent:

1. `self_checked` accepted arbitrary text even though only three bounded
   self-consistency assertion kinds are legitimate.
2. Self-generated fixtures are encoded and adjudicated by FFmpeg. MediaInfo
   could provide a second implementation for some numeric fields, but it was
   not installed in the target environment and did not recognize every format.

The archived project plan also requires the harness to reject an undecidable
field presented as oracle-backed. The pre-unit shell treated unknown field
kinds as labels and could accept a literal `null` from a missing FFprobe path,
so this unit closed those adjacent schema holes as part of the same
oracle-boundary hardening.

## Goals

- Enforce a closed, exact vocabulary for recorded self-consistency claims.
- Keep self-checked claims visibly weaker than oracle-backed comparisons.
- Cross-check known-equivalent numeric values with MediaInfo when available.
- Keep MediaInfo optional at installation and field-support boundaries.
- Make usable MediaInfo values authoritative: a disagreement must turn the
  gate red.
- Reject malformed sidecars and missing FFprobe oracle values early.
- Preserve all existing differential and red-team behavior.

## Non-goals

- The harness will not prove that a listed `self_checked` assertion exists in
  the `.ksy` or force lazy Kaitai instances to execute. The settled sidecar
  schema records assertion kinds as strings; evaluating assertion paths would
  require a separate object schema and explicitly scoped harness unit.
- MediaInfo will not become a required dependency.
- MediaInfo labels will not be compared with FFprobe codec identifiers.
- The unit will not change format parsers, samples, or the declared
  `self-generated` / `third-party` independence regimes.

## Sidecar contract

### Required shape

The harness will validate these properties before compilation:

- `sample` is a non-empty string.
- `independence` is exactly `self-generated` or `third-party`.
- `fields` is a non-empty array.
- Every field has non-empty `name`, `kaitai_path`, and `ffprobe_path` strings.
- Every field kind is exactly `numeric` or `label`.
- At least one field remains `numeric`.
- `self_checked` is an array of unique strings, including when it is empty.

The only accepted, case-sensitive `self_checked` values are:

- `chunk-size-sum == file length`
- `monotonic offsets`
- `declared-count == walked-count`

These values remain output as `self-checked (recorded, NOT oracle-backed)` and
never contribute to the numeric oracle floor.

### Optional MediaInfo mapping

A numeric field may add a non-empty `mediainfo_path` jq expression. A label
field may not declare one. Format-specific knowledge therefore remains beside
the existing Kaitai and FFprobe mappings instead of being hidden in
`check.sh`.

Only mappings observed to be both available and semantically equivalent in
MediaInfo 24.01 will be added initially:

| Format and field | MediaInfo jq path |
|---|---|
| `au.sample_rate` | `.media.track \| map(select(."@type" == "Audio"))[0].SamplingRate` |
| `au.channels` | `.media.track \| map(select(."@type" == "Audio"))[0].Channels` |
| `aiff.channels` | `.media.track \| map(select(."@type" == "Audio"))[0].Channels` |
| `aiff.bits_per_sample` | `.media.track \| map(select(."@type" == "Audio"))[0].BitDepth` |
| `dpx.width` | `.media.track \| map(select(."@type" == "Image"))[0].Width` |
| `dpx.height` | `.media.track \| map(select(."@type" == "Image"))[0].Height` |

AIFF `sample_frames` stays unmapped: MediaInfo's `SamplingCount` is defined in
terms of sampling rate and reported 84 for the fixture whose COMM header and
FFprobe report 80 sample frames. VOC and RoQ stay unmapped because MediaInfo
24.01 opened those files but emitted no useful media track. All third-party
units and codec labels also remain unmapped.

MediaInfo documents the default JSON as a `media.track` array with raw fields
including `Width`, `Height`, `SamplingRate`, `Channels`, and `BitDepth`; its
leaf values are serialized as strings and absent values are omitted. Sources:
[CLI output option](https://github.com/MediaArea/MediaInfo/blob/d327f8fe76208f0b70bc08e4b55dca508991500d/Source/CLI/Help.cpp#L53-L63),
[JSON exporter](https://github.com/MediaArea/MediaInfoLib/blob/dd11d7971107e1b554e41ed446387d22cb3198e9/Source/MediaInfo/MediaInfo_Inform.cpp#L538-L603),
and [field definitions](https://mediaarea.net/en/MediaInfo/Support/Fields).

## Gate data flow

For a normal `./check.sh <fmt>` run:

1. Validate the complete sidecar contract.
2. Compile the `.ksy` with the pinned Kaitai toolchain.
3. Parse the sample and extract all declared Kaitai values.
4. Run FFprobe once and compare every field as today.
5. Reject an FFprobe result that is null, empty, or otherwise not a single
   usable scalar. Numeric comparisons normalize integer-equivalent strings.
6. If the sidecar contains MediaInfo mappings, resolve the binary from the
   `PALIMPSEST_MEDIAINFO_BIN` environment override when set, otherwise from
   `PATH`. A set but unusable override is a configuration error and turns the
   gate red.
7. If found, run it once as JSON with continuous-file-name detection disabled
   so a single DPX fixture remains an `Image` track:

   ```text
   mediainfo --Output=JSON --File_TestContinuousFileNames=0 <sample>
   ```

8. For each mapped field, extract the value with its `mediainfo_path` and
   normalize numeric strings before comparison.
9. Print recorded self-checks and an explicit MediaInfo checked/skipped
   summary, then retain the sidecar's original independence regime in the
   final green line.

MediaInfo is run at most once per sample and is not resolved or invoked when a
sidecar has no mappings. The environment override exists only to select an
executable deterministically in tests or unusual installations; normal users
need no configuration.

## MediaInfo error semantics

The approved best-effort boundary is per installation and per field:

- Binary absent: print that all mapped MediaInfo fields were skipped; keep the
  FFprobe-backed gate result.
- Valid JSON but a mapped path is absent, null, or empty: skip that field
  visibly and continue.
- A mapped value is present and equal: print a second-oracle success line and
  count it as checked.
- A mapped value is present and differs: RED.
- The installed/overridden command exits non-zero, emits malformed JSON, or
  emits a non-scalar ambiguous mapped value: RED. A broken available oracle
  must not silently degrade to absence.

No whole-unit independence upgrade is inferred. Output reports the exact
number of mapped fields checked and skipped, leaving the reader to see the
scope of the added evidence.

## Test strategy

Implementation followed red-green-refactor cycles through
`./check.sh --selftest`.

1. Added failing sidecar-validation tests for an unknown/near-match
   `self_checked` token, malformed list shapes, duplicates, an unknown field
   kind, and null FFprobe oracle output.
2. Added passing validation coverage for an empty list and each canonical
   token.
3. Added a deterministic fake MediaInfo executable and failing tests for a
   numeric mismatch, malformed JSON, command failure, and ambiguous output.
4. Added green tests for a matching numeric value, a missing mapped field that
   is visibly skipped, and binary absence.
5. Kept the original toy compile/parse smoke and all four original red-team
   cases biting, especially `redteam/au_wrong_offset.ksy`.
6. Ran every implemented format gate after selftest, including staged
   third-party fixtures, and confirmed the repository was clean after the final
   commit.

## Documentation impact

The green implementation completed its repository documentation impact:

- `DESIGN.md` records the settled Tier-2 schema and error semantics while
  retaining its frozen-contract status.
- `BACKLOG.md` marks Tier 2 done.
- `README.md` describes the optional second-oracle output.

Atelier state remains outside this repository and is handled during the
umbrella session's normal clock-out protocol.
