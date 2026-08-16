# Palimpsest backlog

Palimpsest is a machine-validated catalogue of game-era media headers. Each
format is described by a Kaitai `.ksy` spec and checked against `ffprobe` with
`./check.sh <format>`.

## Current state

**Tiers 1–5 complete; Tier 6 Wave A and Wave B complete (2026-08-16).**
Twenty-one specs GREEN. Seven Wave C FATE heads remain staged.

- Pinned toolchain + `ffprobe` 6.1.1. FATE heads restore with
  `./harness/stage_heads.py`.
- `./check.sh --selftest` is GREEN (9/9).
- Design note: `docs/superpowers/specs/2026-08-16-tier6-expansion-design.md`.
- `DESIGN.md` stays **frozen**. Wave C authoring units touch only that
  format's `.ksy` and sidecar.

**Next dispatchable unit:** Wave C `vmd` (Sample **STAGED**).

## How a cold agent picks this up

1. Read `AGENTS.md` and frozen `DESIGN.md`.
2. Take **exactly one** Wave C row whose Sample column says **STAGED**
   and which is not yet GREEN.
3. Authoring unit touches only that format's `.ksy`, sidecar, sample (Wave A)
   or `.ksy` + sidecar (Wave C). Never another format, never the harness,
   never `redteam/`.
4. Gate: `./check.sh <fmt>` must be GREEN. State the independence regime
   from the row. Gallery flag is part of the claim — keep it accurate.
5. After green: flip the row, add a `QUARRY-HANDOFF.md` inventory line,
   commit. Then stop or take the next unchecked row.

A decode-only head is **not** dispatchable until Wave B has marked it STAGED.

## Existing inventory (Tiers 1–5) — GREEN

| Format | Check | Sample/source |
|---|---|---|
| ALP (`alp`) | GREEN | self-generated |
| APM (`apm`) | GREEN | self-generated |
| Argonaut ASF (`argo_asf`) | GREEN | self-generated |
| AST (`ast`) | GREEN | self-generated |
| AU | GREEN | self-generated |
| Sega FILM (`film_cpk`) | GREEN | self-generated |
| Westwood AUD (`wsaud`) | GREEN | self-generated |
| VOC | GREEN | self-generated |
| RoQ | GREEN | self-generated |
| Smacker (`smk`) | GREEN | staged FATE head |
| SMJPEG (`smjpeg`) | GREEN | self-generated |
| Bink | GREEN | staged FATE head |
| Westwood VQA (`wsvqa`) | GREEN | staged FATE head |
| Interplay MVE (`ipmovie`) | GREEN | staged FATE head |
| KVAG (`kvag`) | GREEN | self-generated |
| FLIC/FLC | GREEN | staged FATE head |
| GameCube THP (`thp`) | GREEN | staged FATE head |
| Xbox XMV (`xmv`) | GREEN | staged FATE head |
| LucasArts Smush (`smush`) | GREEN | staged FATE head |
| AIFF | GREEN | self-generated |
| DPX | GREEN | self-generated |

## Tier 6 — Wave A (encodable tail)

Self-generated with pinned ffmpeg 6.1.1. Independence: **self-generated**.
Gallery (re-checked 2026-08-16): all **net-new**. Do **not** edit frozen
`harness/gen_samples.sh`; record the exact command in `samples/SOURCES.md`
(AIFF/DPX precedent). Prefer `-map_metadata -1 -fflags +bitexact`.

| Slug | Format | Status | Sample recipe | Oracle floor | Advisory Quarry ID |
|---|---|---|---|---|---|
| `film_cpk` | Sega FILM (Saturn/Dreamcast) | GREEN | `testsrc=32x24:duration=0.5:rate=15`, `-an -c:v cinepak -f film_cpk` → `samples/film_cpk/test.cpk` | width, height, num_frames, fps_num, fps_den, codec_name | `sega.film` |
| `wsaud` | Westwood AUD | GREEN | `sine=440:duration=0.2`, `-ar 22050 -ac 1 -c:a adpcm_ima_ws -f wsaud` → `samples/wsaud/sine.aud` | sample_rate, channels, payload_size, codec_name | `westwood.aud` |
| `ast` | Nintendo AST | GREEN | `sine=440:duration=0.2`, `-ar 32000 -ac 2 -c:a pcm_s16be_planar -f ast` → `samples/ast/sine.ast` | sample_rate, channels, bits_per_sample, num_samples, codec_name | `nintendo.ast` |
| `argo_asf` | Argonaut ASF (Croc) | GREEN | `sine=440:duration=0.2`, `-ar 22050 -ac 1 -f argo_asf -name sine` → `samples/argo_asf/sine.asf` | sample_rate, channels, num_frames, duration_samples, codec_name | `argo.asf` |
| `alp` | LEGO Racers ALP | GREEN | `sine=440:duration=0.2`, `-ar 22050 -ac 1 -f alp` → `samples/alp/sine.alp` | sample_rate, channels, duration_samples, codec_name | `lego.alp` |
| `apm` | Ubisoft APM | GREEN | `sine=440:duration=0.2`, `-ar 22050 -ac 1 -f apm` → `samples/apm/sine.apm` | sample_rate, channels, file_size, duration_samples, codec_name | `ubisoft.apm` |
| `kvag` | Simon & Schuster KVAG | GREEN | `sine=440:duration=0.2`, `-ar 22050 -ac 1 -f kvag` → `samples/kvag/sine.kvag` | sample_rate, channels, data_size, duration_samples, codec_name | `ssi.kvag` |
| `smjpeg` | Loki SMJPEG | GREEN | `testsrc=32x24:duration=0.5:rate=15`, `-an -c:v mjpeg -f smjpeg` → `samples/smjpeg/test.mjpg` | width, height, duration_ms, codec_name | `loki.smjpeg` |

Mux + numeric ffprobe fields were verified on this host 2026-08-16 against
ffprobe 6.1.1-3ubuntu5. Re-probe before authoring if ffmpeg has drifted.

## Tier 6 — Wave B (staging unit)

**DONE 2026-08-16.** Extended `harness/stage_heads.py` `HEADS` with the ten
Wave C FATE paths. Payloads stay gitignored under `samples/_staged/`.
sha256 pinned (TOFU then freeze). `samples/SOURCES.md` rows added.
`./check.sh --selftest` still 9/9. No `.ksy` authored in this unit.

## Tier 6 — Wave C (decode-only heads)

Independence: **third-party**. Gallery: all **net-new** as of 2026-08-16.
Dispatchable only when Sample says STAGED.

| Slug | Format | Sample | FATE path | Advisory Quarry ID |
|---|---|---|---|---|
| `thp` | GameCube THP | GREEN | `thp/pikmin2-opening1-partial.thp` | `nintendo.thp` |
| `xmv` | Xbox XMV | GREEN | `xmv/logos1p.fmv` | `xbox.xmv` |
| `smush` | LucasArts Smush | GREEN | `smush/ronin_part.znm` | `lucasarts.smush` |
| `vmd` | Sierra VMD | STAGED | `vmd/12.vmd` | `sierra.vmd` |
| `idcin` | id CIN | STAGED | `idcin/idlog-2MB.cin` | `id.cin` |
| `wc3` | Westwood WC3 movie | STAGED | `wc3movie/SC_32-part.MVE` | `westwood.wc3` |
| `4xm` | 4X / 4XM | STAGED | `4xm/version1.4xm` | `4x.4xm` |
| `yop` | Psygnosis YOP | STAGED | `yop/test1.yop` | `psygnosis.yop` |
| `brstm` | Nintendo BRSTM | STAGED | `brstm/lozswd_partial.brstm` | `nintendo.brstm` |
| `psxstr` | PS1 STR | STAGED | `psx-str/abc000_cut.str` | `sony.str` |

`wc3` is **not** Interplay MVE (`ipmovie`). Different container, same `.MVE`
extension.

After each Wave C green, add the row to `QUARRY-HANDOFF.md`. Palimpsest green
does not queue a Quarry extractor; Stratum still owns priority.

## Tier 6 — Wave D (parked reserve)

Not authorized unless a later session explicitly adds them. FATE dirs exist:

PAF (`paf/hod1-partial.paf`), DXA, BMV, C93 (`cyberia-c93/intro1.c93`),
SOL, SIFF, Bethsoft VID, Delphine CIN, Maxis XA, BFSTM.

## Exclusions (do not author)

- ADX / HCA / AIX — Codex Restituta / Quarry own the payload
- WAV, IVF, CAF, W64, SOX, IRCAM — not game-era; some already in the Kaitai gallery
- Disc / filesystem layouts — Substratum
- Codec math inside any of these files — header / chunk structure only

## Other remaining work

- [x] **Quarry handoff delivered** (2026-08-16). `QUARRY-HANDOFF.md`.
- [ ] **Optional gallery PR** — only if the project becomes public and the
      user wants it. Existing AU/VOC are gallery-improving; the original eight
      plus every Tier 6 slug above are net-new candidates as of 2026-08-16.

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
- [x] Contract-only Quarry feeder handoff documented (`8b14dca`).
- [x] Tier 6 expansion authorized and queued (2026-08-16).
- [x] Wave A `film_cpk` GREEN (2026-08-16).
- [x] Wave A `wsaud` GREEN (2026-08-16).
- [x] Wave A `ast` GREEN (2026-08-16).
- [x] Wave A `argo_asf` GREEN (2026-08-16).
- [x] Wave A `alp` GREEN (2026-08-16).
- [x] Wave A `apm` GREEN (2026-08-16).
- [x] Wave A `kvag` GREEN (2026-08-16).
- [x] Wave A `smjpeg` GREEN (2026-08-16). Wave A complete.
- [x] Wave B FATE staging (2026-08-16). Ten Wave C heads pinned.
- [x] Wave C `thp` GREEN (2026-08-16).
- [x] Wave C `xmv` GREEN (2026-08-16).
- [x] Wave C `smush` GREEN (2026-08-16).

## How to verify the project

From the repository root:

```bash
./check.sh --selftest
for f in au voc roq smk bink wsvqa ipmovie flic aiff dpx film_cpk wsaud ast argo_asf alp apm kvag smjpeg thp xmv smush; do
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
- Advisory Quarry IDs in the Tier 6 tables are names only — not registry
  reservations and not a Quarry backlog.
- Read `AGENTS.md` before authoring a new unit and `DESIGN.md` for the frozen
  harness and sidecar contract.
