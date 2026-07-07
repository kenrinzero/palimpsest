# Palimpsest

A machine-validated catalogue of game-era media container headers —
Smacker, Bink, Westwood VQA, Interplay MVE, FLIC, RoQ, DPX, VOC, AU —
written as language-neutral **Kaitai Struct** `.ksy` specs and proven by a
**differential gate**: the compiled Kaitai parser and `ffprobe -of json`
must agree, field by field, on real bytes. A spec that merely compiles, or
merely re-detects magic bytes, does not pass — at least one numeric,
offset-sensitive field must match the oracle.

## Status

Stage-0 seed (2026-07-07): pinned portable toolchain (Temurin 21.0.11 +
ksc 0.11 at `~/opt/kaitai`, re-creatable via `toolchain/provision.sh`),
generic harness live, **all four red-team cases proven** (wrong-offset
spec, compile failure, empty oracle map, label-only map — each drives
`check.sh` red), starter samples generated with sidecars authored.
**No real `.ksy` specs yet** — S1 (`au`) is the first floor unit
(`BACKLOG.md`).

## How a unit works

```bash
./check.sh --selftest          # after any harness change
# author formats/<fmt>.ksy against the sidecar's expected fields
./check.sh <fmt>               # compile -> parse -> differential vs ffprobe
```

Green = the spec and FFmpeg agree on real, offset-parsed values, under the
independence regime the sidecar declares (self-generated vs third-party —
see DESIGN.md § 4).

## License

MIT. Generated samples are self-authored; decode-only head samples carry
per-file provenance (`samples/SOURCES.md`).
