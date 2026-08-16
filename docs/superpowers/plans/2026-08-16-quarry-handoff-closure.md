# Palimpsest Quarry Handoff Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the approved contract-only Palimpsest-to-Quarry handoff, synchronize both repositories, and move Palimpsest from `active` to `maintained` without changing production code or format evidence.

**Architecture:** Palimpsest remains the canonical private owner of Kaitai specifications, sidecars, provenance, and parser-validation evidence. Public Quarry records only the maintainer-side feeder boundary; Stratum prevalence selects any later one-format Quarry implementation unit. Closure is documentation-only and preserves the distinction between validated parsing and implemented extraction.

**Tech Stack:** Markdown, Git, WSL Ubuntu, PowerShell, Python 3 read-only assertions, Atelier/Katflow control plane.

## Global Constraints

- The approved design is `docs/superpowers/specs/2026-08-16-quarry-handoff-design.md` at Palimpsest commit `3af269d`.
- Palimpsest implementation/spec evidence remains anchored at `9533efc`; later commits are documentation-only.
- Do not change production source, `.ksy` files, sidecars, samples, harnesses, fixtures, package metadata, or Quarry registry entries.
- Do not copy Palimpsest content into Quarry, add a cross-repository runtime dependency, publish a private/local path, or add an inaccessible required link to public Quarry documentation.
- Do not create ten speculative Quarry work units. A future unit exists only after Stratum ranks its format.
- Keep every touched text file strict UTF-8 with LF-only newlines. Use `apply_patch` for edits.
- Run Palimpsest commands in native WSL at `/home/kenrin/projects/palimpsest`; run Quarry commands at `C:\Users\kenrin\Project\Quarry`.
- This closure is Tier 3. A future one-format Quarry extractor is normally Tier 2; novel reverse engineering beyond the canonical Palimpsest spec is Tier 1.

---

## Task 1: Land the canonical Palimpsest feeder contract

**Files:**
- Create: `QUARRY-HANDOFF.md`
- Modify: `README.md`
- Modify: `DESIGN.md`
- Modify: `BACKLOG.md`
- Modify through the verified clock-out protocol: `C:\Users\kenrin\Project\.atelier\projects\coding\palimpsest\brief.md`, `log.md`, `C:\Users\kenrin\Project\.atelier\logs\2026-W33.md`, and `C:\Users\kenrin\Project\.atelier\INDEX.md`

- [ ] **Step 1: Open and verify a Palimpsest session**

  From `C:\Users\kenrin\Project`, follow the `clock-in` skill for `coding/palimpsest`. With no existing Codex row reported, run exactly once:

  ```powershell
  katflow clock-in --agent "Codex" swe coding/palimpsest
  katflow status --agent "Codex"
  ```

  Expected: exactly one non-stale `OPEN` Codex session for `coding/palimpsest`, status `active`, dependencies `none`.

- [ ] **Step 2: Create `QUARRY-HANDOFF.md` with the frozen ownership contract**

  Write these sections in order:

  1. `Purpose` — Palimpsest proves bounded parser/header facts; it does not implement Quarry extraction.
  2. `Ownership boundary` — Palimpsest owns `.ksy`, sidecars, provenance, and parser gates; Quarry owns `Extractor`, `AssetTree`, extraction/repacking/decoding, fixtures, and registry acceptance; Stratum owns priority.
  3. `Validated format inventory` — exactly the ten rows below.
  4. `Future Quarry unit protocol` — one ranked format per unit; extend/re-gate Palimpsest first if structure is missing; implement independently in Quarry; pass Quarry's current verification and mutation floors; record the exact Palimpsest commit used.
  5. `Drift and privacy rules` — no copied specs/generated parsers/runtime coupling; no claim that Palimpsest green means Quarry extraction green; public Quarry material must remain sufficient without access to this private repository.
  6. `Verification entry points` — link `README.md`, `DESIGN.md`, `samples/SOURCES.md`, the sidecars, and cite `./check.sh --selftest` plus a concrete example such as `./check.sh aiff`.

  Use this exact inventory data. `Candidate Quarry ID` is advisory and is not a registry reservation.

  | Format | Candidate Quarry ID | Canonical inputs | Sample / provenance | Independence | Oracle-backed fields | Self-checked claims | Demonstrated parser depth | Quarry extraction |
  |---|---|---|---|---|---|---|---|---|
  | AIFF (`aiff`) | `iff.aiff` | `formats/aiff.ksy`; `formats/aiff.fields.json` | `samples/aiff/sine.aiff`; `samples/SOURCES.md` | self-generated | channels, sample_frames, bits_per_sample, sample_rate, codec_name | chunk-size-sum == file length | FORM/COMM/SSND walk, 80-bit sample-rate decode, malformed-size floors | Not implemented |
  | AU (`au`) | `sun.au` | `formats/au.ksy`; `formats/au.fields.json` | `samples/au/sine.au`; `samples/SOURCES.md` | self-generated | sample_rate, channels, codec_name | None | fixed header/data-offset parse and short-offset validity floor | Not implemented |
  | Bink (`bink`) | `rad.bink` | `formats/bink.ksy`; `formats/bink.fields.json` | `samples/_staged/bink/RazOnBull.bik`; `samples/SOURCES.md` | third-party | width, height, file_size, num_frames, fps_num, fps_den, audio_tracks, audio_sample_rate, audio_channels, audio_codec, video_codec | declared-count == walked-count | header, audio-track tables, and frame-offset table walk | Not implemented |
  | DPX (`dpx`) | `smpte.dpx` | `formats/dpx.ksy`; `formats/dpx.fields.json` | `samples/dpx/test.dpx`; `samples/SOURCES.md` | self-generated | width, height, codec_name | None | generic/image headers and image geometry | Not implemented |
  | FLIC/FLC (`flic`) | `autodesk.flic` | `formats/flic.ksy`; `formats/flic.fields.json` | `samples/_staged/flic/jj00c2.fli`; `samples/SOURCES.md` | third-party | width, height, frame_delay_msec, file_size, codec_name | chunk-size-sum == file length | file header plus frame/chunk walk, ring-frame handling, size/geometry floors | Not implemented |
  | Interplay MVE (`ipmovie`) | `interplay.mve` | `formats/ipmovie.ksy`; `formats/ipmovie.fields.json` | `samples/_staged/ipmovie/descent3-level5-16bit-partial.mve`; `samples/SOURCES.md` | third-party | width, height, video_codec, audio_sample_rate, audio_channels, audio_codec | None | chunk/opcode walk through video and audio initialization | Not implemented |
  | RoQ (`roq`) | `id.roq` | `formats/roq.ksy`; `formats/roq.fields.json` | `samples/roq/test.roq`; `samples/SOURCES.md` | self-generated | width, height, frame_rate, codec_name | chunk-size-sum == file length | chunk walk and QUAD_INFO geometry with known-id/rate floors | Not implemented |
  | Smacker (`smk`) | `rad.smk` | `formats/smk.ksy`; `formats/smk.fields.json` | `samples/_staged/smk/wetlogo.smk`; `samples/SOURCES.md` | third-party | width, height, frame_duration_units, total_frames, video_codec, audio_sample_rate, audio_channels, audio_codec | declared-count == walked-count | header, audio-track metadata, and per-frame size/type tables | Not implemented |
  | VOC (`voc`) | `creative.voc` | `formats/voc.ksy`; `formats/voc.fields.json` | `samples/voc/sine.voc`; `samples/SOURCES.md` | self-generated | sample_rate, channels, codec_name | declared-count == walked-count | chained VOC block walk with rate/channel extraction and validity floors | Not implemented |
  | Westwood VQA (`wsvqa`) | `westwood.vqa` | `formats/wsvqa.ksy`; `formats/wsvqa.fields.json` | `samples/_staged/wsvqa/small-cut-v3.vqa`; `samples/SOURCES.md` | third-party | width, height, frames, finf_entries, frame_rate, sample_rate, channels, video_codec, audio_codec | declared-count == walked-count | FORM/VQHD parse and FINF/frame-offset traversal | Not implemented |

- [ ] **Step 3: Synchronize Palimpsest's current-state documents**

  Apply these exact semantic changes:

  - `README.md`: describe the project as maintained; link `QUARRY-HANDOFF.md`; state that the handoff supplies parser/specification evidence only, and that Stratum-ranked executable integration belongs to a future Quarry unit.
  - `DESIGN.md` §6: replace the stale sentence that the Quarry handoff remains deferred. State that the contract-only handoff is delivered in `QUARRY-HANDOFF.md`, while executable extraction remains deferred to Stratum-ranked Quarry units.
  - `BACKLOG.md`: change the current-state date to 2026-08-16; replace the stale `main`/`origin/main` equality claim with an implementation/spec baseline at `9533efc` plus later documentation-only handoff commits; mark the Quarry handoff complete with a pointer to `QUARRY-HANDOFF.md`; retain only the optional gallery/publication decision as unchecked and explicitly gated on the project becoming public and the user requesting it; replace the historical direct personal-name wording with `the user`.

- [ ] **Step 4: Verify the Palimpsest inventory and text hygiene**

  Run from `/home/kenrin/projects/palimpsest`:

  ```bash
  python3 - <<'PY'
  import json
  from pathlib import Path

  root = Path('.')
  handoff = (root / 'QUARRY-HANDOFF.md').read_text(encoding='utf-8')
  formats = ('aiff', 'au', 'bink', 'dpx', 'flic', 'ipmovie', 'roq', 'smk', 'voc', 'wsvqa')
  rows = [line for line in handoff.splitlines() if line.startswith('| ') and '`formats/' in line]
  assert len(rows) == 10, len(rows)
  assert {path.stem.removesuffix('.fields') for path in (root / 'formats').glob('*.fields.json')} == set(formats)
  assert {path.stem for path in (root / 'formats').glob('*.ksy')} == set(formats)
  for fmt in formats:
      sidecar_path = root / 'formats' / f'{fmt}.fields.json'
      sidecar = json.loads(sidecar_path.read_text(encoding='utf-8'))
      row = next(line for line in rows if f'`formats/{fmt}.ksy`' in line)
      assert f'`formats/{fmt}.fields.json`' in row
      assert sidecar['sample'] in row
      assert sidecar['independence'] in row
      assert ', '.join(field['name'] for field in sidecar['fields']) in row
      expected_self = ', '.join(sidecar['self_checked']) or 'None'
      assert expected_self in row
  for name in ('QUARRY-HANDOFF.md', 'README.md', 'DESIGN.md', 'BACKLOG.md'):
      data = (root / name).read_bytes()
      data.decode('utf-8', errors='strict')
      assert b'\r\n' not in data, name
  print('inventory ok: 10; text ok: strict UTF-8/LF')
  PY
  rg -n "handoff remains deferred|wait for Quarry to graduate|Quarry hand-off remains deferred" README.md DESIGN.md BACKLOG.md QUARRY-HANDOFF.md
  git diff --check
  git status --short
  ```

  Expected: the Python assertion prints `inventory ok: 10; text ok: strict UTF-8/LF`; `rg` returns no matches; `git diff --check` is silent; status lists only the four intended documentation files plus this already-committed plan if it has not yet been committed by the planner.

- [ ] **Step 5: Commit and push the Palimpsest documentation**

  ```bash
  git add QUARRY-HANDOFF.md README.md DESIGN.md BACKLOG.md
  git diff --cached --check
  git commit -m "Document the Quarry feeder handoff"
  git push origin main
  git status --short --branch
  ```

  Expected: one documentation-only commit; push succeeds; `main...origin/main` has no ahead/behind marker and the worktree is clean.

- [ ] **Step 6: Close the first Palimpsest session as still active**

  Before clock-out, use `apply_patch` to convert the design-review item in the Palimpsest brief to this concise completed pointer: `2026-08-16 — The contract-only handoff design was approved; see the project log.` Follow the `clock-out` skill's katflow-authored ordinary path. Record that the private canonical feeder contract and local state documents landed and were pushed, while the public Quarry boundary note and final maintained transition remain. Keep brief status `active`; keep the completed design pointer and replace the remaining open items with the single closure step plus the optional gallery item. Verify scoped status/history and run `atelier health`; accept only zero errors (the pre-existing repairable research-Workspace warning may remain).

---

## Task 2: Record the public Quarry boundary without leaking private details

**Files:**
- Modify: `C:\Users\kenrin\Project\Quarry\README.md`
- Modify: `C:\Users\kenrin\Project\Quarry\BACKLOG.md`
- Modify through the verified clock-out protocol: `C:\Users\kenrin\Project\.atelier\projects\coding\quarry\brief.md`, `log.md`, `C:\Users\kenrin\Project\.atelier\logs\2026-W33.md`, and `C:\Users\kenrin\Project\.atelier\INDEX.md`

- [ ] **Step 1: Open and verify a Quarry session**

  From `C:\Users\kenrin\Project`, follow the `clock-in` skill for `coding/quarry`:

  ```powershell
  katflow clock-in --agent "Codex" swe coding/quarry
  katflow status --agent "Codex"
  ```

  Expected: exactly one non-stale `OPEN` Codex session for `coding/quarry`; the project is `maintained` and has no hard-stop dependency.

- [ ] **Step 2: Add the public boundary note**

  - In `README.md` under `## Boundary`, add one paragraph stating that a private maintainer-side Palimpsest feeder contract catalogs validated media-header specifications and evidence; it is specification input only, creates no runtime dependency or registry slot, and becomes a Quarry unit only when Stratum prevalence ranks the format.
  - In `BACKLOG.md` under `## Known follow-ups (non-blocking)`, add one bullet with the same operational rule: the feeder contract is maintainer-side, no extractor is queued from availability alone, and a selected format is implemented independently against Quarry's public interfaces and verification policy.
  - Do not include a filesystem path, private repository URL, required private link, ten-format inventory, copied `.ksy`/sidecar content, or a speculative extractor identifier.

- [ ] **Step 3: Verify the public/private boundary and documentation-only scope**

  From `C:\Users\kenrin\Project\Quarry` run:

  ```powershell
  rg -n "Palimpsest|feeder contract|Stratum" README.md BACKLOG.md
  rg -n "\\\\wsl\$|/home/kenrin|github\.com/kenrinzero/palimpsest|formats/.+\.ksy|\.fields\.json" README.md BACKLOG.md
  git diff --check
  git diff --name-only
  git status --short
  ```

  Expected: the first command finds only the new concise boundary notes; the second returns no matches; `git diff --check` is silent; only `README.md` and `BACKLOG.md` are modified. Do not rerun Quarry's code gates because no source, test, registry, or fixture changed; cite the last verified `192 passed, 7 skipped` gate in the Atelier handoff.

- [ ] **Step 4: Commit and push Quarry**

  ```powershell
  git add README.md BACKLOG.md
  git diff --cached --check
  git commit -m "Document the Palimpsest feeder boundary"
  git push origin main
  git status --short --branch
  ```

  Expected: one documentation-only commit; push succeeds; `main...origin/main` has no ahead/behind marker and the worktree is clean.

- [ ] **Step 5: Clock out Quarry as maintained**

  Follow the `clock-out` skill's katflow-authored ordinary path. State that the public boundary note is pushed, contains no private path or duplicated inventory, and queues no extractor. Keep status `maintained`; keep the current Stratum-prevalence gate as the next step. Verify scoped status/history and `atelier health`, requiring zero errors.

---

## Task 3: Verify both repositories and close Palimpsest as maintained

**Files:**
- Modify: `C:\Users\kenrin\Project\.atelier\projects\coding\palimpsest\brief.md` through the verified clock-out protocol
- Modify: `C:\Users\kenrin\Project\.atelier\projects\coding\palimpsest\log.md` through the verified clock-out protocol
- Modify: `C:\Users\kenrin\Project\.atelier\logs\2026-W33.md` through the verified clock-out protocol
- Modify: `C:\Users\kenrin\Project\.atelier\INDEX.md` through the verified clock-out protocol

- [ ] **Step 1: Run final read-only repository assertions**

  ```powershell
  wsl.exe -d Ubuntu -- bash -lc "cd /home/kenrin/projects/palimpsest && git status --short --branch && git rev-parse HEAD && git rev-parse origin/main && git diff --check && rg -n 'wait for Quarry to graduate|handoff remains deferred|Quarry hand-off remains deferred' README.md DESIGN.md BACKLOG.md QUARRY-HANDOFF.md"
  git -C "C:\Users\kenrin\Project\Quarry" status --short --branch
  git -C "C:\Users\kenrin\Project\Quarry" rev-parse HEAD
  git -C "C:\Users\kenrin\Project\Quarry" rev-parse origin/main
  git -C "C:\Users\kenrin\Project\Quarry" diff --check
  rg -n "\\\\wsl\$|/home/kenrin|github\.com/kenrinzero/palimpsest|formats/.+\.ksy|\.fields\.json" "C:\Users\kenrin\Project\Quarry\README.md" "C:\Users\kenrin\Project\Quarry\BACKLOG.md"
  ```

  Expected: both repositories are clean and synchronized (`HEAD` equals `origin/main`); both `rg` commands return no matches; both diff checks are silent.

- [ ] **Step 2: Open the final Palimpsest closure session**

  From `C:\Users\kenrin\Project`, follow the `clock-in` skill again:

  ```powershell
  katflow clock-in --agent "Codex" swe coding/palimpsest
  katflow status --agent "Codex"
  ```

  Expected: exactly one non-stale `OPEN` Codex session for `coding/palimpsest`, still `active` before closure.

- [ ] **Step 3: Prepare the concise brief and INDEX transition**

  Before clock-out, use `apply_patch` to update both the brief's repository line and the Palimpsest INDEX row's repository cell to the exact short `origin/main` hash observed in Step 1. Preserve the completed design-approval pointer from Task 1, and convert the remaining closure item into this concise completed pointer:

  - `2026-08-16 — Palimpsest and Quarry handoff documentation landed and synchronized; see the project log.`

  Leave one open item only: `Consider an upstream Kaitai gallery PR only if the project becomes public and the user wants it.`

- [ ] **Step 4: Preview and execute the maintained clock-out exactly once**

  Follow the `clock-out` skill's katflow-authored ordinary path. Use these semantics in both the dry-run and byte-for-byte-equivalent real command:

  - Detailed project-log summary: both repositories received and pushed their documentation-only handoff changes; Palimpsest owns canonical specs/evidence, Quarry owns executable extraction, Stratum owns priority; deterministic inventory/privacy/UTF-8/LF/diff checks passed; no production files changed and existing code gates were not rerun.
  - Week summary: `Closed Palimpsest as a maintained specification feeder after pushing the contract-only Quarry handoff and verifying both repositories.`
  - Decision: `Future Quarry integration is one Stratum-ranked format per unit; Palimpsest green never substitutes for Quarry extraction evidence.`
  - Open/next: the optional gallery/publication decision remains separately user-gated.
  - Brief status: `maintained`; the INDEX row must render the same status, last-touched date, and repository hash.
  - Brief current: `All ten format specs and gates are complete; the contract-only Quarry handoff is documented and synchronized, with future extractor work selected by Stratum prevalence.`
  - Brief next: `Consider an upstream Kaitai gallery PR only if the project becomes public and the user wants it.`

  Required command order: scoped status → full dry-run → equivalent real command once → scoped status → scoped history → `atelier health`. Require no open Codex row, one completion for the final session, exact brief/INDEX status and date agreement, exactly one project-log block and week-log line, zero health errors, and no new warning beyond the known repairable research-Workspace warning.

- [ ] **Step 5: Confirm the terminal project boundary**

  Read the final Palimpsest brief, newest Palimpsest log entry, current week tail, and matching INDEX row. Confirm:

  - Palimpsest is `maintained`, last touched 2026-08-16, and the brief/INDEX repository references both name the synchronized short `origin/main` hash.
  - The current state is a one-sentence maintained snapshot.
  - Only the optional, explicitly user-gated gallery item remains open.
  - Both Git repositories remain clean and synchronized after control-plane closure.
  - No source/spec/sidecar/sample/harness/test/fixture changes occurred in the closure commits.
