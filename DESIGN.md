# Palimpsest — Design Contract (FROZEN)

> **Status: FROZEN at seed time (2026-07-07).** This document + `check.sh`
> semantics + the `formats/<fmt>.fields.json` sidecar schema are the
> contract. Harness changes and new self-consistency assertion kinds are
> explicitly-scoped units; an authoring unit only ever adds
> `formats/<fmt>.ksy`, its sidecar, and (for the encodable tail) its
> generated sample.

Machine-validated Kaitai Struct specs for game-era media container
headers, proven by a **differential gate**: the compiled `.ksy` parser and
`ffprobe -of json` must agree, field by field, on real bytes.

## 0. Environment re-audit — 2026-07-07 (build start; plan facts CONFIRMED)

- `ffprobe 6.1.1-3ubuntu5` + `jq` present (the oracle pair).
- `ksc` / `java` / `kaitaistruct` were absent; **no passwordless sudo** →
  toolchain provisioned PORTABLE and PINNED (§ 1), which is the better
  pinning posture anyway.
- Muxer split re-confirmed exactly: `smk`/`bink`/`wsvqa`/`ipmovie`/`flic`
  have **no muxer** (decode-only head, samples must be pre-staged);
  `au`/`voc`/`roq` encodable (self-generating tail).
- Kaitai gallery re-checked live (formats.kaitai.io): only `au` and
  `creative_voice_file` exist → those two are *gallery-improving*; all
  seven game-era targets (Smacker, Bink, VQA, MVE, FLIC, RoQ, DPX) are
  **net-new**.
- `mediainfo` not present — second-oracle policy is best-effort (§ 5).

## 1. Pinned toolchain (settled)

Portable install at `~/opt/kaitai/` (outside the repo; no sudo needed):

- **JRE:** Eclipse Temurin **21.0.11** (Adoptium `linux/x64/jre`) at
  `~/opt/kaitai/jre`
- **Compiler:** **kaitai-struct-compiler 0.11** at `~/opt/kaitai/compiler`
  — note: NEWER than the plan's 0.10-era assumption; 0.11 is what upstream
  ships today and what this corpus is pinned to.
- **Python runtime:** `kaitaistruct` via uv in this repo (see pyproject).

All harness invocations go through `toolchain/ksc` (wrapper exporting
`JAVA_HOME` and calling the pinned compiler by absolute path). Re-running
`toolchain/provision.sh` re-creates the install; drift in any component =
re-run the § 0 audit as its own unit.

**Target language (settled):** the conformance gate compiles
`--target python` only. The corpus stays language-neutral by nature of
`.ksy`; a second-target smoke-compile (C++/JS) is a deferred, explicitly-
scoped harness unit — not baked in now.

## 2. The sidecar schema (settled) — `formats/<fmt>.fields.json`

```json
{
  "sample": "samples/<fmt>/<file>",
  "independence": "self-generated" | "third-party",
  "fields": [
    {"name": "sample_rate",
     "kaitai_path": "sample_rate",          // attribute chain on the parsed object
     "ffprobe_path": ".streams[0].sample_rate",  // jq path
     "kind": "numeric" | "label",
     "mediainfo_path": ".media.track | map(select(.\"@type\" == \"Audio\"))[0].SamplingRate"}
  ],
  "self_checked": ["<kaitai valid:/instance assertions — recorded, Tier-2 enforced>"]
}
```

Tier-2 hardening (settled 2026-07-21): `self_checked` is a required array
of unique strings from exactly `chunk-size-sum == file length`,
`monotonic offsets`, and `declared-count == walked-count`. These entries
remain recorded claims and never count as oracle-backed. Sidecar field kinds
are closed to `numeric` and `label`, independence tags are closed to the two
regimes above, and every FFprobe path must resolve to one non-null scalar.

A numeric field may opt into the best-effort second oracle with a non-empty
`mediainfo_path`. If MediaInfo is absent, or valid output omits that field,
the mapping is visibly skipped. A present disagreement, unusable configured
binary, command failure, malformed JSON, or non-scalar result turns the gate
red. The final independence tag is unchanged; output reports exact
MediaInfo checked/skipped counts.

Harness rules encoded mechanically (red-team-enforced): `fields` must be
non-empty; **≥ 1 field with `kind: numeric`** (a `label`-only map — e.g.
`codec_name` — is rejected: magic re-detection is not parsing). Numeric
comparison converts both operands with jq's `tonumber` and requires exact
numeric equality (ffprobe emits `sample_rate` as a string but `width` as a
number — a known quirk); neither value is truncated.

## 3. The gate (`check.sh <fmt>`)

sidecar sanity (complete schema, canonical self-check vocabulary, non-empty
numeric oracle floor) → compile gate (`toolchain/ksc --target python`) →
parse the sample with the compiled parser (`harness/extract.py`) → pull each
required field from `ffprobe -of json` as one non-null scalar →
field-by-field compare → optionally run MediaInfo once and compare every
available mapped numeric field → report self-checked claims separately →
non-zero exit on any required-oracle or available-second-oracle mismatch.

`check.sh --selftest` drives the original four red-team cases, the toy
compile/parse smoke, strict sidecar-vocabulary cases, the null-oracle
anti-model, deterministic optional-MediaInfo match/skip/failure cases,
and malformed-input fixtures (undersized AIFF FORM, AU short offset).
Run it after any harness change.

## 4. Independence regimes (settled tagging)

- `self-generated` (encodable tail): FFmpeg both encoded and adjudicates —
  the differential is independent **of the spec** (the error class we
  author) but not of FFmpeg. Green claims exactly that, nothing more.
- `third-party` (decode-only head): author ≠ FFmpeg ≠ Kaitai — full
  independence, the stronger regime.
- MediaInfo cross-checking is **best-effort field-level corroboration**:
  mapped numeric fields are compared when the optional CLI returns usable
  values, but no whole-unit independence upgrade is inferred; it is never a
  hard dependency.

## 5. Red-team cases (all four proven at seed time)

(a) **wrong-but-compilable spec** — `redteam/au_wrong_offset.ksy` reads
`sample_rate` at the encoding field's offset; against the real generated
AU sample the differential must go RED (3 ≠ 8000);
(b) **compile failure** — `redteam/toy_compilefail.ksy` must fail the
compile gate;
(c) **empty oracle map** — `redteam/empty.fields.json` must be rejected;
(d) **label-only map** — `redteam/labelonly.fields.json` (`codec_name`
alone) must be rejected.

Tier-2 adds boundary fixtures without weakening or renumbering these original
four cases: malformed sidecars and unknown self-check claims are rejected, a
missing FFprobe path cannot pass as the literal label `null`, and fake
MediaInfo output proves matching, partial-support, mismatch, malformed,
non-scalar, command-failure, and bad-override behavior.

Malformed-input hardening (2026-07-25): selected specs carry explicit
`valid` floors so truncated or lying size fields fail at parse time —
AIFF `form_size` ≥ 46 (form type + COMM + minimal SSND), classic COMM
payload length 18, SSND payload ≥ 8; AU `data_offset` ≥ 24 with non-zero
rate/channels; RoQ non-zero frame rate and known chunk ids; FLIC
size/frame geometry floors; MVE non-empty init chunk streams; Bink and
VOC non-zero geometry/rate floors. Fixtures under `redteam/`
(`aiff_undersized_form`, `aiff_form_too_small_for_ssnd`,
`au_short_offset`, `roq_zero_rate`, `flic_tiny_size`,
`mve_empty_first_chunk`) are proven red by `./check.sh --selftest`
section 9/9.

The full GREEN differential path is completed by starter unit S1's correct
`au.ksy` (deliberately left to the floor — the wrong-offset red proves the
machinery end-to-end without stealing the unit).

## 6. Sample policy (settled)

Encodable tail: generated by the frozen `ffmpeg -f lavfi` recipes in
`harness/gen_samples.sh`, committed with sha256 in `samples/SOURCES.md`.
Decode-only head: pre-staged by a web-capable prep unit — committed ONLY
if clearly-redistributable or self-authored-via-original-tools; otherwise
a gitignored `samples/_staged/` cache with a refetchable manifest
(provenance row either way). Tier-2's bounded self-consistency vocabulary is
landed. Deeper or new assertion semantics require a future explicitly scoped
harness unit. The contract-only Quarry handoff is delivered in
`QUARRY-HANDOFF.md`; executable extraction remains deferred to one-format
Quarry units selected by Stratum prevalence.

## 7. What the seed shipped vs did not

Shipped: pinned toolchain + provision script, generic harness
(check.sh + extract.py), sidecar schema, four red-team fixtures proven,
three starter samples generated + sidecars authored, BACKLOG with strata/
gallery flags. NOT shipped: any real `.ksy` (S1–S3 floor units), the
Tier-2 self-consistency enforcement, head-format sample staging (Tier 3).
