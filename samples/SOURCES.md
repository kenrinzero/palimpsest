# samples/ — provenance ledger

Encodable-tail samples are SELF-AUTHORED via the frozen recipes in
harness/gen_samples.sh (ffmpeg 6.1.1, 2026-07-07) and committed; they are
frozen — regeneration is a deliberate unit. Decode-only head samples are
staged by Tier-3 prep units with per-file provenance added here.

| file | bytes | provenance | sha256 |
|---|---|---|---|
| `samples/au/sine.au` | 16032 | self-generated (gen_samples.sh) | `8f5722c33392373da27dd75d890d452e849311cdc748bb370c0f3ce41fcd4197` |
| `samples/voc/sine.voc` | 22269 | self-generated (gen_samples.sh) | `3b0783fb372c3ec120a59afbad1aa241b330e547bfcff9b3d39dea03c93f416e` |
| `samples/roq/test.roq` | 9432 | self-generated (gen_samples.sh) | `3c638a31a5e0a28892c6986a8afe603af36e541976d4cf844b3940c84d3d6713` |

## Decode-only heads — STAGED 2026-07-17 (Tier-3 prep unit)

Third-party real bytes from the FFmpeg FATE suite
(`fate-suite.ffmpeg.org` — the corpus ffmpeg tests these demuxers
against, so oracle compatibility is by construction). No clear
redistribution license → payloads live in gitignored `samples/_staged/`;
refetch byte-exact via `harness/stage_heads.py` (sha256-pinned in the
script; upstream per-dir `md5sum` cross-checked where it lists the
file). Probed green with the pinned ffprobe 6.1.1 at staging time —
every sample exposes numeric oracle fields. **Independence regime for
all five: full** (third-party bytes, spec- and sample-independent).

| file (gitignored) | bytes | origin (fate-suite path) | ffprobe 6.1.1 at staging |
|---|---|---|---|
| `_staged/smk/wetlogo.smk` | 724092 | `smacker/wetlogo.smk` (upstream md5 ok) | smk: smackvideo 320×200 @1000/71 + smackaudio 22050Hz/1ch |
| `_staged/bink/RazOnBull.bik` | 383828 | `bink/RazOnBull.bik` | bink: binkvideo 640×480 @30 + binkaudio_dct 44100Hz/2ch |
| `_staged/wsvqa/small-cut-v3.vqa` | 92160 | `vqa/small-cut-v3.vqa` | wsvqa: ws_vqa 140×110 @15 + adpcm_ima_ws 22050Hz/1ch |
| `_staged/ipmovie/descent3-level5-16bit-partial.mve` | 1048576 | `interplay-mve/descent3-level5-16bit-partial.mve` (upstream md5 ok) | ipmovie: interplayvideo 640×320 @12500/417 + interplay_dpcm 44100Hz/2ch |
| `_staged/flic/jj00c2.fli` | 901390 | `fli/jj00c2.fli` (upstream md5 ok) | flic: flic 640×480 @125/9 (video-only) |

Full sha256 values are pinned in `harness/stage_heads.py` (a refetch
fails loudly on drift).

Toolchain pin (DESIGN.md sec.1): Temurin JRE 21.0.11 + kaitai-struct-compiler 0.11
+ pypi kaitaistruct 0.11, at ~/opt/kaitai (re-create: toolchain/provision.sh).
