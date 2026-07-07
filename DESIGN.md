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
     "kind": "numeric" | "label"}
  ],
  "self_checked": ["<kaitai valid:/instance assertions — recorded, Tier-2 enforced>"]
}
```

Harness rules encoded mechanically (red-team-enforced): `fields` must be
non-empty; **≥ 1 field with `kind: numeric`** (a `label`-only map — e.g.
`codec_name` — is rejected: magic re-detection is not parsing). Numeric
comparison normalizes both sides through `str(int(x))` (ffprobe emits
`sample_rate` as a string but `width` as a number — a known quirk).

## 3. The gate (`check.sh <fmt>`)

sidecar sanity → compile gate (`toolchain/ksc --target python`) → parse
the sample with the compiled parser (`harness/extract.py`) → pull the same
fields from `ffprobe -of json` via `jq` → field-by-field compare →
non-zero exit on ANY mismatch. Output states the unit's **independence
regime** (§ 4) and lists `self_checked` entries as *"recorded, not
oracle-backed"* so the two guarantees are never conflated.

`check.sh --selftest` drives the four red-team cases and the toy
compile/parse smoke; run it after any harness change.

## 4. Independence regimes (settled tagging)

- `self-generated` (encodable tail): FFmpeg both encoded and adjudicates —
  the differential is independent **of the spec** (the error class we
  author) but not of FFmpeg. Green claims exactly that, nothing more.
- `third-party` (decode-only head): author ≠ FFmpeg ≠ Kaitai — full
  independence, the stronger regime.
- `mediainfo` cross-checking (absent in-env today) is **best-effort**: if
  installed later, a Tier-2 unit wires it to upgrade self-generated units;
  it is never a hard dependency.

## 5. Red-team cases (all four proven at seed time)

(a) **wrong-but-compilable spec** — `redteam/au_wrong_offset.ksy` reads
`sample_rate` at the encoding field's offset; against the real generated
AU sample the differential must go RED (3 ≠ 8000);
(b) **compile failure** — `redteam/toy_compilefail.ksy` must fail the
compile gate;
(c) **empty oracle map** — `redteam/empty.fields.json` must be rejected;
(d) **label-only map** — `redteam/labelonly.fields.json` (`codec_name`
alone) must be rejected.

The full GREEN differential path is completed by starter unit S1's correct
`au.ksy` (deliberately left to the floor — the wrong-offset red proves the
machinery end-to-end without stealing the unit).

## 6. Sample policy (settled)

Encodable tail: generated by the frozen `ffmpeg -f lavfi` recipes in
`harness/gen_samples.sh`, committed with sha256 in `samples/SOURCES.md`.
Decode-only head: pre-staged by a web-capable prep unit — committed ONLY
if clearly-redistributable or self-authored-via-original-tools; otherwise
a gitignored `samples/_staged/` cache with a refetchable manifest
(provenance row either way). Deep-dive self-consistency vocabulary and the
Quarry hand-off are deferred exactly as the plan schedules them (Tier 2 /
cross-plan).

## 7. What the seed shipped vs did not

Shipped: pinned toolchain + provision script, generic harness
(check.sh + extract.py), sidecar schema, four red-team fixtures proven,
three starter samples generated + sidecars authored, BACKLOG with strata/
gallery flags. NOT shipped: any real `.ksy` (S1–S3 floor units), the
Tier-2 self-consistency enforcement, head-format sample staging (Tier 3).
