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

Palimpsest is active on a Tier 6 expansion. Thirty-eight specs are
differential-GREEN. Waves A–D are complete. See `BACKLOG.md`.

Shipped (Tiers 1–5, 2026-07-25): AU, VOC, RoQ, Smacker, Bink, Westwood VQA,
Interplay MVE, FLIC/FLC, AIFF, and DPX. Tier 6 Wave A: `film_cpk`, `wsaud`,
`ast`, `argo_asf`, `alp`, `apm`, `kvag`, `smjpeg`. Wave C: `thp`,
`xmv`, `smush`, `vmd`, `idcin`, `wc3`, `fourxm`, `yop`, `brstm`,
`psxstr`. Wave D: `paf`, `dxa`, `bmv`, `c93`, `sol`, `siff`, `bethsoftvid`, `dsicin`, `xa`, `bfstm`.

**Breadth (Tier 4)** and **depth (Tier 5)** are complete for the planned
set, including Bink audio/frame-offset tables and full VOC block walks.
**Malformed-input hardening** adds explicit `valid` floors (AIFF, AU,
RoQ, FLIC, MVE, Bink, VOC) with redteam fixtures under
`./check.sh --selftest` (9/9).

**Kaitai gallery** (re-checked 2026-08-16): only `au` and
`creative_voice_file` exist upstream — those two are gallery-improving;
every other shipped format, including `film_cpk`, is **net-new**.

Harness: Temurin 21.0.11 + Kaitai compiler 0.11, pinned under
`~/opt/kaitai` via `toolchain/provision.sh`.

## Clone / develop

```bash
# 1. Toolchain (once per machine; no sudo — installs under ~/opt/kaitai)
./toolchain/provision.sh

# 2. Python deps
uv sync

# 3. Self-generated samples are in-tree. Decode-only FATE heads are
#    gitignored (license murk) — refetch once:
uv run python harness/stage_heads.py

# 4. Gates
./check.sh --selftest
./check.sh au   # or any shipped format, including film_cpk
```

Pinned oracle: **ffprobe 6.1.1**. If system FFmpeg drifts, stop and re-audit
(DESIGN.md § 0).

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

## Quarry feeder handoff

[`QUARRY-HANDOFF.md`](QUARRY-HANDOFF.md) is the canonical maintainer-side
contract for using these specifications as evidence in future Quarry work. It
supplies validated parser/header facts only: it does not implement extraction,
create a Quarry registry slot, or add a runtime dependency. Stratum prevalence
selects any future one-format Quarry unit, which must independently pass
Quarry's current extraction and verification contract.

## Contributors

- Claude Fable 5 (Claude Code)
- DeepSeek V4 Pro (Reasonix)
- GPT-5.6 Sol (Codex)
- Kimi K2.7 Code (Kimi Code)
- Grok 4.5 (Grok Build)
- Grok 4.6 (Grok Build)

## License

MIT. Generated samples are self-authored; decode-only head samples carry
per-file provenance (`samples/SOURCES.md`).
