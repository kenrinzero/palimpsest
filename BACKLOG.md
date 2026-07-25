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
| S1 `au` | T3 | improving | **DONE 2026-07-19** (Reasonix), reconciled 2026-07-21 (Codex). Complete 24-byte BE header; pinned FFmpeg 6.1.1 encoding map; sample-rate, channels, and codec oracles GREEN. |
| S2 `voc` | T3 | improving | **DONE 2026-07-19** (Reasonix), reconciled 2026-07-21 (Codex); full block walk **DONE 2026-07-25** (Grok). Type-9 first block + type-2 continuations through type-0 terminator; sample-rate/channels/codec GREEN. |
| S3 `roq` | T3 | **net-new** | **DONE 2026-07-19** (Reasonix), reconciled 2026-07-21 (Codex). Validated 8-byte header and bounded chunk walk through the first QUAD_INFO, including valid sound-before-info order; dimensions, frame rate, and codec oracles GREEN. |

## Tier 2 — oracle/self-checked boundary hardening — DONE 2026-07-21

`self_checked` now accepts only the three canonical bounded consistency
claims and never contributes oracle credit. Sidecars reject unknown kinds,
regimes, and unusable oracle paths. AU, AIFF, and DPX carry proven numeric
MediaInfo mappings that run when the optional CLI is installed; missing
support skips visibly, while usable disagreements and broken output go red.

## Tier 3 — decode-only head sample staging — DONE 2026-07-17

FATE-suite bytes (no clear license → gitignored `samples/_staged/`,
refetch via `harness/stage_heads.py`, sha256-pinned; provenance + probe
values in `samples/SOURCES.md`). If `_staged/` is missing, run the script
once before checking a head unit. All five staged head units below are now
implemented and GREEN.

| format | sample | provenance rule |
|---|---|---|
| smk (Smacker) | **DONE 2026-07-19** (Reasonix), reconciled 2026-07-21 (Codex) | BOUNDED FIXED HEADER: 104 bytes; 320×200, signed timing, smackvideo, GREEN |
| bink | **DONE 2026-07-19** (Reasonix), reconciled 2026-07-21 (Codex); depth **DONE 2026-07-25** (Grok) | Base header + audio tracks + `num_frames+1` frame-offset table; audio 44100/2ch/binkaudio_dct and num_frames GREEN |
| wsvqa (Westwood VQA) | **DONE 2026-07-19** (Reasonix), reconciled 2026-07-21 (Codex) | COMPLETE VQHD: 42-byte mixed-BE/LE header; dimensions/frame/audio fields, ws_vqa, GREEN |
| ipmovie (Interplay MVE) | **DONE 2026-07-19** (Reasonix), reconciled 2026-07-21 (Codex) | BOUNDED OPCODE WALK: first INIT_VIDEO chunk through INIT_VIDEO_BUFFERS; 640×320 (stored/8 → ×8), interplayvideo, GREEN |
| flic (FLIC/FLC) | **DONE 2026-07-19** (Reasonix), reconciled 2026-07-21 (Codex) | BOUNDED FIXED HEADER: 128 bytes; 640×480 plus FLC timing oracle, flic, GREEN. Eight implemented specs now pass (3 self-generated + 5 third-party). |

## Tier 4 — breadth — DONE 2026-07-21

The five staged head formats plus the two final self-generated breadth
units are complete.

| format | result | independence and numeric oracle |
|---|---|---|
| aiff | **DONE 2026-07-21** (Codex) | **Net-new**; self-generated 80-frame PCM sample; bounded FORM/chunk walk through COMM; channels, sample frames, and bits/sample GREEN. |
| dpx | **DONE 2026-07-21** (Codex) | **Net-new**; self-generated image2/DPX sample; endian selected from SDPX/XPDS; width and height at the standard image-information offsets GREEN. |

## Malformed-input hardening — DONE 2026-07-25 (Grok)

Explicit `valid` floors (expanded same day):

| format | floors |
|---|---|
| aiff | form_size ≥ 46; COMM len == 18; SSND len ≥ 8 |
| au | data_offset ≥ 24; sample_rate/channels ≥ 1 |
| roq | frame_rate ≥ 1; known chunk ids; QUAD_INFO len ≥ 8 |
| flic | size ≥ 128; frames/width/height ≥ 1; oframe1 ≥ 128; frame ≥ 16; subchunk ≥ 6 |
| ipmovie | first/second chunk data lens ≥ 4 |
| bink | num_frames/width/height/fps ≥ 1; audio sample_rate ≥ 1 |
| voc | data_offset ≥ 26; type-9 rate/channels ≥ 1 |

Redteam fixtures (selftest 9/9): `aiff_undersized_form`,
`aiff_form_too_small_for_ssnd`, `au_short_offset`, `roq_zero_rate`,
`flic_tiny_size`, `mve_empty_first_chunk`. Good samples stay GREEN.

## Tier 5 — depth + novel RE (routed sparingly, T1, three-attempt cap)

Only on formats whose header already passes; self-checked depth fields
explicitly labelled (recorded, not oracle-backed).

| format | result | depth claim |
|---|---|---|
| smk | **DONE 2026-07-25** (Grok) | Structured 104-byte header remainder (7 audio-size slots, treesize + four Huffman sizes, 7× rate/flags tracks, pad) plus per-frame size and type tables sized by `total_frames`. Audio oracles GREEN: sample_rate 22050, channels 1, smackaudio. Frame count GREEN vs `duration_ts`. self_checked: `declared-count == walked-count`. |
| ipmovie | **DONE 2026-07-25** (Grok) | Second-chunk INIT_AUDIO (0x0000) walk through INIT_AUDIO_BUFFERS (0x03); FFmpeg-aligned flags → channels/bit-depth/DPCM and sample_rate at payload +4. Audio oracles GREEN: 44100 Hz, 2 ch, interplay_dpcm. Video path unchanged. |
| aiff | **DONE 2026-07-25** (Grok) | IEEE 80-bit extended sample-rate → integer Hz (8000 GREEN); continued chunk walk through SSND (offset/block_size); codec_label pcm_s16be; self_checked `chunk-size-sum == file length` (form_size+8). |
| flic | **DONE 2026-07-25** (Grok) | oframe1/oframe2 + eos frame/subchunk walk (0xF1FA records, COLOR_256/DELTA_FLC/BYTE_RUN); file_size oracle vs `.format.size`; self_checked `chunk-size-sum == file length`. |
| wsvqa | **DONE 2026-07-25** (Grok) | IFF walk VQHD→FINF; FINF entry count == num_frames (96); audio_codec adpcm_ima_ws; self_checked `declared-count == walked-count`. FORM size not used as bound (FATE partial). |
| roq | **DONE 2026-07-25** (Grok) | Full chunk stream to EOF (INFO + codebooks + VQ frames); dimensions from leading QUAD_INFO; self_checked `chunk-size-sum == file length`. |
| bink | **DONE 2026-07-25** (Grok) | Audio track table + `num_frames+1` frame-offset index; primary audio rate/channels/codec + frame count GREEN. self_checked: `declared-count == walked-count`. |
| voc | **DONE 2026-07-25** (Grok) | Full block walk type-9 → type-2… → type-0 terminator; oracles still from first type-9. |

## Gallery status (re-checked 2026-07-25)

Live formats.kaitai.io still lists only `au` and `creative_voice_file`
among this corpus. **Gallery-improving:** `au`, `voc`. **Net-new:**
`roq`, `smk`, `bink`, `wsvqa`, `ipmovie`, `flic`, `aiff`, `dpx`.
