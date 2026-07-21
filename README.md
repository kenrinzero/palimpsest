# Palimpsest

A machine-validated catalogue of game-era media container headers —
Smacker, Bink, Westwood VQA, Interplay MVE, FLIC, RoQ, DPX, AIFF, VOC,
and AU —
written as language-neutral **Kaitai Struct** `.ksy` specs and proven by a
**differential gate**: the compiled Kaitai parser and `ffprobe -of json`
must agree, field by field, on real bytes. A spec that merely compiles, or
merely re-detects magic bytes, does not pass — at least one numeric,
offset-sensitive field must match the oracle.

## Status

Ten specs are implemented and differential-GREEN as of 2026-07-21:
AU, VOC, RoQ, Smacker, Bink, Westwood VQA, Interplay MVE, FLIC/FLC,
AIFF, and DPX. The five self-generated samples and five hash-pinned
third-party samples all match `ffprobe` on numeric, offset-sensitive
fields; the parsers also validate format identities and bound fixed
headers and chunk payloads. Tier 4 breadth is complete.

The Stage-0 harness remains pinned to Temurin 21.0.11 and Kaitai compiler
0.11, with all four red-team cases proven to drive `check.sh` red.

## How a unit works

```bash
./check.sh --selftest          # after any harness change
# author formats/<fmt>.ksy against the sidecar's expected fields
./check.sh <fmt>               # compile -> parse -> differential vs ffprobe
```

Green = the spec and FFmpeg agree on real, offset-parsed values, under the
independence regime the sidecar declares (self-generated vs third-party —
see DESIGN.md § 4).

Sidecars may also declare canonical `self_checked` consistency claims, always
reported as recorded and not oracle-backed. Selected numeric fields in the
self-generated AU, AIFF, and DPX units opt into MediaInfo as a best-effort
second oracle. MediaInfo is not required; each run reports exactly which
mapped fields were checked or skipped.

## License

MIT. Generated samples are self-authored; decode-only head samples carry
per-file provenance (`samples/SOURCES.md`).
