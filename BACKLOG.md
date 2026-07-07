# Palimpsest — Unit Backlog

One authoring unit = bring ONE format's header to a green `./check.sh
<fmt>` (compile gate + differential vs ffprobe). Units add
`formats/<fmt>.ksy` (+ sidecar edits) only — the harness, toolchain, and
red-team fixtures are frozen (DESIGN.md). After any harness change, run
`./check.sh --selftest`. Encodable tail first; a head unit is dispatchable
only when its sample row below is STAGED.

## Stage 0 — DONE at seed (2026-07-07)

Toolchain pinned (Temurin 21.0.11 + ksc **0.11** — newer than the plan's
0.10 assumption), harness live, all four red-team cases proven to bite,
starter samples generated + sidecars authored.

## Starter units (encodable tail; sidecars + samples ready)

| unit | tier | gallery | notes |
|---|---|---|---|
| S1 `au` | T3 | improving (gallery has `au` — our contribution is the conformance gate) | 24-byte BE header. Sidecar expects `sample_rate`/`channels` numeric + `codec_name` label via a `codec_label` instance (map encoding 3 → `pcm_s16be`). The wrong-offset red-team fixture is the anti-model: read the REAL offsets. |
| S2 `voc` | T3 | improving | 26-byte magic + version, block-chained body; sidecar expects first-block rate/channels (`first_block_sample_rate`/`first_block_channels` instances) + `codec_label` (`pcm_u8` for the default first block — verify against the sample with ffprobe, not from memory). |
| S3 `roq` | T3 | **net-new** (first video unit; exercises the chunk-walk the head formats reuse) | Signature `0x1084`, chunk stream, `RoQ_QUAD_INFO` carrying width/height (`quad_info.width`/`.height` instances). |

## Tier 2 — oracle/self-checked boundary hardening (T2 harness unit)

Enforce the `self_checked` vocabulary (chunk-size-sum == file length,
monotonic offsets, declared-count == walked-count); wire `mediainfo`
cross-checking if/when installed (best-effort — DESIGN § 4).

## Tier 3 — decode-only head sample staging (T1/web prep, one row per format)

| format | sample | provenance rule |
|---|---|---|
| smk (Smacker) | NOT STAGED | tiny clearly-redistributable clip or self-authored via original tools; commit only if license-clean, else `samples/_staged/` cache + manifest (DESIGN § 6) |
| bink | NOT STAGED | same |
| wsvqa (Westwood VQA) | NOT STAGED | same |
| ipmovie (Interplay MVE) | NOT STAGED | same |
| flic (FLIC/FLC) | NOT STAGED | same |

## Tier 4 — breadth (after starters green)

aiff, dpx (via image2), then the staged head formats — each a header unit
with ≥1 numeric oracle field, independence regime tagged.

## Tier 5 — depth + novel RE (routed sparingly, T1, three-attempt cap)

FLIC delta-chunk opcodes, Smacker per-frame size tables + audio flags, VQA
codebooks, MVE opcode stream — only on formats whose header already
passes; self-checked depth fields explicitly labelled.
