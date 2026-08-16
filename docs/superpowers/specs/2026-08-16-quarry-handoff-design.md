# Palimpsest to Quarry handoff design

## Decision

Close Palimpsest's active phase with a contract-only feeder handoff. Palimpsest
remains the canonical owner of its Kaitai Struct specifications and their
validation evidence. Quarry records how future extractor units consume that
evidence, but it does not copy the `.ksy` files, vendor generated parsers, add
a runtime dependency on Palimpsest, or register speculative extractor slots.

After the handoff documentation lands, Palimpsest moves from `active` to
`maintained`. Executable integrations are future Quarry units selected by
Stratum prevalence, one format per session.

## Context

Palimpsest has completed its planned implementation scope: ten `.ksy` specs,
ten field-map sidecars, a pinned Kaitai toolchain, five staged FFmpeg FATE
heads, five self-generated samples, differential gates, the 9/9 self-test,
malformed-input floors, and recorded independence regimes.

Quarry now has a different contract. A Quarry `Extractor` consumes a bounded
normalized target, emits a typed `AssetTree`, and is accepted only after its
round-trip, idempotence, or differential policy passes. A Palimpsest parser
validates container/header structure and selected fields; that is useful
specification evidence, but it is not an asset extractor and cannot be
registered directly without overstating what it proves.

The old instruction to wait for Quarry to graduate is satisfied. The
remaining work is to freeze the ownership boundary and make the completed
Palimpsest evidence easy for future Quarry units to consume.

## Goals

- Preserve one canonical copy of every Palimpsest `.ksy` specification.
- Give future Quarry authors a concise inventory of the ten validated formats
  and the exact evidence available for each.
- Prevent a green header/parser gate from being described as green extraction.
- Defer executable integration until Stratum demonstrates prevalence and
  therefore priority.
- Let Palimpsest leave the active queue without losing its feeder role.

## Non-goals

- No Quarry production extractor is implemented in this handoff.
- No generated Kaitai parser is committed to Quarry.
- No Palimpsest source, sample, or sidecar is copied into Quarry.
- No new common package, cross-repository runtime dependency, or registry
  metadata field is introduced.
- No Kaitai gallery submission or public-release decision is made.
- No bulk plan is created to integrate all ten formats.

## Ownership boundary

### Palimpsest owns

- `formats/<format>.ksy` and `formats/<format>.fields.json`;
- the pinned Kaitai/FFprobe conformance harness;
- sample provenance and independence-regime labels;
- claims about parsed header/container structure and validated fields;
- corrections or extensions to the format specification.

### Quarry owns

- the `Extractor` and `AssetTree` contracts;
- unpacking, repacking, decoding, and asset naming behavior;
- real-fixture extraction inventories and verification policies;
- production registry acceptance;
- mining manifests and prevalence-directed extractor ordering.

### Stratum owns priority

Stratum's prevalence-ranked handoff chooses which format, if any, becomes a
Quarry implementation unit. Availability of a Palimpsest spec alone is not a
reason to build an extractor.

## Handoff artifact

Create `QUARRY-HANDOFF.md` at the Palimpsest repository root. It is the stable
human-readable feeder contract and contains:

1. The ownership and non-duplication rules above.
2. A ten-row inventory with:
   - format and Quarry-facing identifier candidate;
   - canonical `.ksy` and sidecar paths;
   - sample class and provenance location;
   - independence regime;
   - oracle-backed fields;
   - self-checked claims;
   - demonstrated parser depth;
   - explicit statement that extraction is not implemented.
3. The future-unit protocol below.
4. Links to Palimpsest's `README.md`, `DESIGN.md`, `samples/SOURCES.md`, and
   verification command.

Palimpsest is currently private while Quarry is public. Quarry's `README.md`
and `BACKLOG.md` therefore record only that a maintainer-side Palimpsest
feeder contract exists and that it does not authorize speculative units. They
do not publish a local path, depend on an inaccessible link, or reproduce the
ten-row inventory. If Palimpsest later becomes public, those references may be
upgraded to a stable repository link as a separate T3 change.

## Future Quarry unit protocol

When Stratum ranks a Palimpsest-covered format:

1. Open one Quarry unit for one format.
2. Read the canonical Palimpsest `.ksy`, sidecar, and handoff row.
3. Confirm that the required extraction behavior is actually described. If
   the parser lacks needed structure, extend Palimpsest first and return its
   gate to green; do not patch a private copy in Quarry.
4. Stage at least the real-fixture floor required by Quarry's current contract.
5. Implement the Quarry extractor independently against Quarry's interfaces.
6. Pass the appropriate Quarry verification mode and mutation/anti-degeneracy
   controls before registry acceptance.
7. Record the exact Palimpsest commit used as maintainer-side specification
   provenance. Public Quarry documentation and tests must still explain and
   prove the extractor without requiring readers to access the private repo.

The ordinary implementation is T2 when Palimpsest already describes the
needed structure. Novel reverse engineering beyond the canonical spec is a
separate T1 Palimpsest unit. Updating links or provenance after a green unit
is T3.

## Failure and drift rules

- A missing or renamed Palimpsest path is a hard stop for a future Quarry
  unit; update the handoff before implementation.
- A generated parser or copied `.ksy` found in Quarry is boundary drift and
  must be removed in favor of the canonical reference.
- A Palimpsest field disagreement is repaired and re-gated in Palimpsest
  before Quarry relies on it.
- Quarry evidence never upgrades Palimpsest's declared independence regime,
  and Palimpsest green never substitutes for Quarry extraction evidence.
- If Stratum does not rank any of the ten formats, no integration work is
  created merely to exercise the handoff.

## Closure changes

The implementation plan for this design is documentation-only:

- add `QUARRY-HANDOFF.md` to Palimpsest;
- update Palimpsest `README.md`, `DESIGN.md`, and `BACKLOG.md` to replace the
  satisfied Quarry-graduation gate with the maintained feeder state;
- record the private maintainer-side feeder boundary in Quarry `README.md` and
  `BACKLOG.md`, without exposing a local path or duplicating the inventory;
- update the Atelier Palimpsest brief, log, week log, and INDEX row, changing
  status from `active` to `maintained`;
- leave the optional gallery/publication item parked and explicitly
  user-gated.

No production source, format spec, sidecar, sample, harness, or test fixture is
changed by closure.

## Verification

- The handoff inventory contains exactly the ten `.ksy` files and ten matching
  sidecars on disk.
- Every handoff path resolves and each independence/self-check claim matches
  its sidecar.
- Quarry contains only the public boundary note, with no copied Palimpsest
  sources, generated parsers, private paths, or inaccessible required links.
- Documentation contains no remaining claim that Quarry has not graduated or
  that the handoff is still externally blocked.
- `git diff --check` passes in both repositories.
- All touched text strict-decodes as UTF-8 and contains LF-only newlines.
- Because closure changes documentation only, existing code gates are cited
  from the last verified state rather than rerun as evidence of a source
  change that did not occur.
