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

Toolchain pin (DESIGN.md sec.1): Temurin JRE 21.0.11 + kaitai-struct-compiler 0.11
+ pypi kaitaistruct 0.11, at ~/opt/kaitai (re-create: toolchain/provision.sh).
