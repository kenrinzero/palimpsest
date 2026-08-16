# Palimpsest Tier 6 expansion design

## Decision

Expand Palimpsest past the original ten-format scope. Keep the frozen
`DESIGN.md` contract (sidecar schema, `check.sh` gate, independence tags,
sample policy). Grow only the format catalogue.

Approach **C** (chosen 2026-08-16): both strata, encodable first. Wave A is
eight self-generated game-era muxers already proven on this host against
ffprobe 6.1.1. Wave B is one staging harness unit. Wave C is ten FATE
decode-only heads, dispatchable only after STAGED. Wave D is a parked reserve.

The dispatch ledger is `BACKLOG.md`. This file is the design record; do not
fork a second unit list.

## Context

Tiers 1–5 shipped ten GREEN specs, the 9/9 selftest, and a contract-only
Quarry handoff (`8b14dca`). Palimpsest was `maintained` with no remaining
planned units. The original plan already named a longer FFmpeg-exotic runway;
this expansion queues that runway without unfreezing the harness except for
the one Wave B edit.

## Goals

- Queue a cold-agent-dispatchable next unit (`film_cpk`).
- Add net-new game-era container/header specs under the existing gate.
- Preserve independence honesty (`self-generated` vs `third-party`).
- Keep decode-only units blocked until samples are staged.
- Leave Quarry/Stratum priority unchanged: green here is not an extractor.

## Non-goals

- No ADX/HCA/AIX work (Codex Restituta / Quarry).
- No disc/filesystem layouts (Substratum).
- No codec math.
- No gallery PR or public-release decision.
- No bulk Quarry integration.
- No change to sidecar vocabulary, red-team fixtures, or `check.sh` semantics
  except adding HEADS entries in Wave B.

## Inventory

See `BACKLOG.md` tables. Summary:

- **Wave A (8, self-generated, net-new):** `film_cpk`, `wsaud`, `ast`,
  `argo_asf`, `alp`, `apm`, `kvag`, `smjpeg`.
- **Wave B:** extend `harness/stage_heads.py`; pin Wave C FATE sha256s;
  `./check.sh --selftest`.
- **Wave C (10, third-party, net-new, UNSTAGED):** `thp`, `xmv`, `smush`,
  `vmd`, `idcin`, `wc3`, `4xm`, `yop`, `brstm`, `psxstr`.
- **Wave D (parked):** PAF, DXA, BMV, C93, SOL, SIFF, Bethsoft VID,
  Delphine CIN, Maxis XA, BFSTM.

Wave A mux/probe was verified 2026-08-16 on ffmpeg/ffprobe 6.1.1-3ubuntu5.
Kaitai gallery re-check the same day still shows only `au` and
`creative_voice_file` among this project's formats.

## Unit protocol

One unit = one format = one GREEN `./check.sh <fmt>`.

- Authoring unit: `formats/<fmt>.ksy` + `formats/<fmt>.fields.json`, and for
  Wave A the generated sample + `samples/SOURCES.md` row.
- Wave A samples use a documented `ffmpeg -f lavfi` command (bitexact flags
  preferred). Do not edit frozen `harness/gen_samples.sh`.
- Wave C authoring starts only when that row says STAGED.
- Sidecar must include ≥1 numeric oracle field. Implement the named
  `kaitai_path`s (instances such as `codec_label` are fine).
- Do not edit the harness, toolchain, red-team fixtures, or another format
  inside an authoring unit. `redteam/au_wrong_offset.ksy` stays deliberately
  wrong.
- After green: update the BACKLOG row, append `QUARRY-HANDOFF.md` (advisory
  Quarry ID only), commit.

## Staging rules (Wave B)

FATE payloads have no clear redistribution license. They live in gitignored
`samples/_staged/` with refetchable pins, same as the existing five heads.
Upstream `md5sum` cross-check remains best-effort; sha256 pin is mandatory.

`wc3` uses FATE dir `wc3movie` and must not be confused with `ipmovie`.

## Docs after units land

- `BACKLOG.md` is the live ledger.
- `QUARRY-HANDOFF.md` gains a row only when that format is GREEN.
- `README.md` status should mention the expansion once the first Wave A
  unit lands.
- Atelier brief returns to `active` while Wave A–C are in progress, then
  `maintained` when the authorized waves are done.

## Risks

- Thin oracle on exotic demuxers: keep the load-bearing fields numeric.
- Self-generated samples are spec-independent, not FFmpeg-independent.
- Wave B is the only harness mutation; if it lands, selftest must stay 9/9.
- ffmpeg drift off 6.1.1 is a STOP + DESIGN § 0 re-audit, not a silent
  sample regen.
