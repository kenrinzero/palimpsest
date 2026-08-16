# Quarry feeder handoff

## Purpose

Palimpsest is the canonical specification and validation-evidence feeder for
the media formats below. Its green gates prove bounded container/header parser
facts against independent oracles under the declared regime. They do not
implement a Quarry extractor, produce a Quarry `AssetTree`, or prove Quarry
extraction behavior.

Candidate Quarry identifiers in this document are advisory names for a future
unit. They are not registry reservations and create no implementation backlog.

## Ownership boundary

Palimpsest owns each canonical `formats/<format>.ksy` specification, its
`formats/<format>.fields.json` sidecar, sample provenance, independence label,
and parser-validation gate. Corrections or extensions to those facts land and
return to green here first.

Quarry owns its `Extractor` and `AssetTree` contracts, extraction, repacking or
decoding behavior, asset naming, real-fixture evidence, verification policy,
and production-registry acceptance. It implements against its public
interfaces rather than importing or registering Palimpsest directly.

Stratum owns priority. Availability of a Palimpsest specification alone does
not queue a Quarry unit.

## Validated format inventory

| Format | Candidate Quarry ID | Canonical inputs | Sample / provenance | Independence | Oracle-backed fields | Self-checked claims | Demonstrated parser depth | Quarry extraction |
|---|---|---|---|---|---|---|---|---|
| AIFF (`aiff`) | `iff.aiff` | `formats/aiff.ksy`; `formats/aiff.fields.json` | `samples/aiff/sine.aiff`; `samples/SOURCES.md` | self-generated | channels, sample_frames, bits_per_sample, sample_rate, codec_name | chunk-size-sum == file length | FORM/COMM/SSND walk, 80-bit sample-rate decode, malformed-size floors | Not implemented |
| AU (`au`) | `sun.au` | `formats/au.ksy`; `formats/au.fields.json` | `samples/au/sine.au`; `samples/SOURCES.md` | self-generated | sample_rate, channels, codec_name | None | fixed header/data-offset parse and short-offset validity floor | Not implemented |
| Bink (`bink`) | `rad.bink` | `formats/bink.ksy`; `formats/bink.fields.json` | `samples/_staged/bink/RazOnBull.bik`; `samples/SOURCES.md` | third-party | width, height, file_size, num_frames, fps_num, fps_den, audio_tracks, audio_sample_rate, audio_channels, audio_codec, video_codec | declared-count == walked-count | header, audio-track tables, and frame-offset table walk | Not implemented |
| DPX (`dpx`) | `smpte.dpx` | `formats/dpx.ksy`; `formats/dpx.fields.json` | `samples/dpx/test.dpx`; `samples/SOURCES.md` | self-generated | width, height, codec_name | None | generic/image headers and image geometry | Not implemented |
| FLIC/FLC (`flic`) | `autodesk.flic` | `formats/flic.ksy`; `formats/flic.fields.json` | `samples/_staged/flic/jj00c2.fli`; `samples/SOURCES.md` | third-party | width, height, frame_delay_msec, file_size, codec_name | chunk-size-sum == file length | file header plus frame/chunk walk, ring-frame handling, size/geometry floors | Not implemented |
| Interplay MVE (`ipmovie`) | `interplay.mve` | `formats/ipmovie.ksy`; `formats/ipmovie.fields.json` | `samples/_staged/ipmovie/descent3-level5-16bit-partial.mve`; `samples/SOURCES.md` | third-party | width, height, video_codec, audio_sample_rate, audio_channels, audio_codec | None | chunk/opcode walk through video and audio initialization | Not implemented |
| RoQ (`roq`) | `id.roq` | `formats/roq.ksy`; `formats/roq.fields.json` | `samples/roq/test.roq`; `samples/SOURCES.md` | self-generated | width, height, frame_rate, codec_name | chunk-size-sum == file length | chunk walk and QUAD_INFO geometry with known-id/rate floors | Not implemented |
| Sega FILM (`film_cpk`) | `sega.film` | `formats/film_cpk.ksy`; `formats/film_cpk.fields.json` | `samples/film_cpk/test.cpk`; `samples/SOURCES.md` | self-generated | width, height, num_frames, fps_num, fps_den, codec_name | declared-count == walked-count | FILM/FDSC/STAB Saturn path, Cinepak fourcc, video-only floor | Not implemented |
| Smacker (`smk`) | `rad.smk` | `formats/smk.ksy`; `formats/smk.fields.json` | `samples/_staged/smk/wetlogo.smk`; `samples/SOURCES.md` | third-party | width, height, frame_duration_units, total_frames, video_codec, audio_sample_rate, audio_channels, audio_codec | declared-count == walked-count | header, audio-track metadata, and per-frame size/type tables | Not implemented |
| VOC (`voc`) | `creative.voc` | `formats/voc.ksy`; `formats/voc.fields.json` | `samples/voc/sine.voc`; `samples/SOURCES.md` | self-generated | sample_rate, channels, codec_name | declared-count == walked-count | chained VOC block walk with rate/channel extraction and validity floors | Not implemented |
| Westwood AUD (`wsaud`) | `westwood.aud` | `formats/wsaud.ksy`; `formats/wsaud.fields.json` | `samples/wsaud/sine.aud`; `samples/SOURCES.md` | self-generated | sample_rate, channels, payload_size, codec_name | chunk-size-sum == file length | 12-byte header plus 0xDEAF chunk walk | Not implemented |
| Westwood VQA (`wsvqa`) | `westwood.vqa` | `formats/wsvqa.ksy`; `formats/wsvqa.fields.json` | `samples/_staged/wsvqa/small-cut-v3.vqa`; `samples/SOURCES.md` | third-party | width, height, frames, finf_entries, frame_rate, sample_rate, channels, video_codec, audio_codec | declared-count == walked-count | FORM/VQHD parse and FINF/frame-offset traversal | Not implemented |

## Future Quarry unit protocol

When Stratum ranks one of these formats:

1. Open one Quarry unit for that one format.
2. Read the canonical Palimpsest specification, sidecar, and inventory row.
3. Confirm that Palimpsest describes the structure needed for extraction. If
   it does not, extend and re-gate Palimpsest first; do not patch a private copy
   in Quarry.
4. Stage the real-fixture floor required by Quarry's current contract.
5. Implement independently against Quarry's public interfaces.
6. Pass Quarry's applicable round-trip, idempotence, or differential policy
   and its mutation/anti-degeneracy controls before registry acceptance.
7. Record the exact Palimpsest commit used as maintainer-side specification
   provenance. Public Quarry documentation and tests must remain sufficient
   without access to this private repository.

This is normally Tier 2 when the required structure is already described.
Novel reverse engineering beyond the canonical specification is a separate
Tier 1 Palimpsest unit. Link or provenance maintenance after a green unit is
Tier 3.

## Drift and privacy rules

- Do not copy a Palimpsest `.ksy`, sidecar, or generated parser into Quarry.
- Do not add a runtime dependency between the repositories or a speculative
  Quarry registry slot.
- Repair field disagreements in Palimpsest and return its gate to green before
  Quarry relies on the corrected fact.
- Palimpsest green never substitutes for Quarry extraction evidence, and
  Quarry evidence never upgrades Palimpsest's independence label.
- Public Quarry material may acknowledge this maintainer-side feeder contract,
  but it must not publish a private path, require an inaccessible link, or copy
  this inventory.
- If Stratum ranks none of these formats, create no integration work merely to
  exercise the handoff.

## Verification entry points

- Project status and gate semantics: [`README.md`](README.md)
- Frozen parser contract: [`DESIGN.md`](DESIGN.md)
- Sample provenance and frozen digests: [`samples/SOURCES.md`](samples/SOURCES.md)
- Canonical specifications and sidecars: [`formats/`](formats/)
- Harness self-test: `./check.sh --selftest`
- One-format differential example: `./check.sh aiff`
