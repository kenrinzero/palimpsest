> **Managed under atelier.** Before starting, read
> `C:\Users\kenrin\Project\.atelier\CHARTER.md` (from WSL:
> `/mnt/c/Users/kenrin/Project/.atelier/CHARTER.md`), the current week log in
> `.atelier\logs\`, and this project's brief + log at
> `.atelier\projects\coding\palimpsest\`. Clock out per the charter when done.

<!-- Project-specific instructions below this line. -->

# Working on Palimpsest

1. **Read `DESIGN.md`** (frozen), then take the next unit from
   `BACKLOG.md`. A decode-only head unit is dispatchable only when its
   sample row says STAGED.
2. **The gate is `./check.sh <fmt>`** — compile + differential vs ffprobe,
   green or red. After ANY harness change also run `./check.sh --selftest`
   (the four red-team cases must keep biting).
3. **Authoring rules:** one unit touches `formats/<fmt>.ksy` (and, for the
   encodable tail, its generated sample via the frozen
   `harness/gen_samples.sh` recipe). Never edit the harness, the
   toolchain, the red-team fixtures, or another format's files inside an
   authoring unit. `redteam/au_wrong_offset.ksy` is DELIBERATELY wrong —
   never "fix" it.
4. **Sidecars define what your spec must expose:** implement the
   `kaitai_path`s the sidecar names (instances are fine — e.g. a
   `codec_label` instance mapping an encoding enum to ffprobe's
   `codec_name` string). Matching `codec_name` alone is worthless; the
   numeric fields are the test.
5. **Toolchain is pinned** (Temurin 21.0.11 + ksc 0.11 at `~/opt/kaitai`,
   invoked via `toolchain/ksc`). If it's missing, run
   `toolchain/provision.sh` (needs web). If system ffprobe stops being
   6.1.1, STOP and re-run the DESIGN § 0 audit as its own unit.
6. **Honesty rules:** state each unit's independence regime (the sidecar
   carries it); `self_checked` entries are recorded but never counted as
   oracle-backed; the gallery-improving vs net-new flag in BACKLOG.md is
   part of the unit's claim — keep it accurate.
