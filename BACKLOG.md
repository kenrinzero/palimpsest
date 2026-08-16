# Palimpsest backlog

Palimpsest is a machine-validated catalogue of game-era media headers. Each
format is described by a Kaitai `.ksy` spec and checked against `ffprobe` with
`./check.sh <format>`.

## Current state

**Healthy, maintained, and complete through the current planned scope.** As of
2026-08-16:

- The implementation/spec baseline is `9533efc`; later commits are
  documentation-only design, planning, and feeder-handoff records.
- All ten format checks are GREEN.
- `./check.sh --selftest` is GREEN: 9/9 checks, including malformed-input
  hardening.
- Tier 2 hardening, Tier 3 head formats, Tier 4 breadth, and Tier 5 depth are
  complete.
- The pinned toolchain and `ffprobe` 6.1.1 gate are in use.
- FATE-derived head samples remain gitignored; restore them with
  `./harness/stage_heads.py` when needed.

There are no unstarted format units in the current plan.

## Format inventory

| Format | Check | Sample/source |
|---|---|---|
| AU | GREEN | self-generated |
| VOC | GREEN | self-generated |
| RoQ | GREEN | self-generated |
| Smacker (`smk`) | GREEN | staged FATE head |
| Bink | GREEN | staged FATE head |
| Westwood VQA (`wsvqa`) | GREEN | staged FATE head |
| Interplay MVE (`ipmovie`) | GREEN | staged FATE head |
| FLIC/FLC | GREEN | staged FATE head |
| AIFF | GREEN | self-generated |
| DPX | GREEN | self-generated |

## Remaining work

These are decisions or handoffs, not blocked implementation units.

- [x] **Quarry handoff delivered.** `QUARRY-HANDOFF.md` records the canonical
  format inventory, evidence boundary, and Stratum-ranked future-unit protocol.
- [ ] **Optional gallery PR — only if the project becomes public and the user
  wants to upstream it.** AU and VOC improve existing gallery coverage; the
  other eight formats are net-new candidates.

Until one of those items is selected, leave the format specs and harness alone.

## Completed milestones

- [x] Toolchain, samples, sidecars, differential harness, and red-team gates
      established.
- [x] AU, VOC, and RoQ starter units completed.
- [x] Sidecar vocabulary, oracle boundaries, and optional MediaInfo checks
      hardened.
- [x] Smacker, Bink, Westwood VQA, Interplay MVE, and FLIC head units
      completed.
- [x] AIFF and DPX breadth units completed.
- [x] Malformed-input floors and red-team coverage completed.
- [x] Deep format walks and numeric fields completed for the Tier 5 set.
- [x] Private GitHub remote created and verified against local `main`.

## How to verify the project

From the repository root:

```bash
./check.sh --selftest
for f in au voc roq smk bink wsvqa ipmovie flic aiff dpx; do
  ./check.sh "$f"
done
```

If the staged FATE samples are absent, run `./harness/stage_heads.py` first.
Use the pinned toolchain through `toolchain/ksc`; if the required toolchain or
`ffprobe` version changes, stop and re-audit `DESIGN.md` before continuing.

## Non-blocking notes

- Kaitai emits style warnings about repeat-count field names in `flic.ksy`,
  `smk.ksy`, and `bink.ksy`; the checks still pass. Treat cleanup as optional.
- MediaInfo is not installed in the current environment, so its optional
  cross-checks are visibly skipped rather than treated as failures.
- Read `AGENTS.md` before authoring a new unit and `DESIGN.md` for the frozen
  harness and sidecar contract.
