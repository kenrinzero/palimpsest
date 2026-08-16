#!/usr/bin/env python3
"""Stage the decode-only head-format samples (Tier-3 five + Wave C ten + Wave D ten).

Source: the FFmpeg FATE suite (fate-suite.ffmpeg.org) — the exact corpus
ffmpeg tests these demuxers against, so ffprobe compatibility is
guaranteed by construction. FATE samples carry no clear redistribution
license, so payloads live in gitignored ``samples/_staged/`` (DESIGN § 6
house pattern); this committed script + the pinned hashes below + the
SOURCES.md rows are the provenance, and re-running refetches byte-exact
or fails loudly.

Each file is verified against the FATE directory's own upstream md5sum
AND our pinned sha256 (TOFU on first fetch, then frozen here).
"""

import hashlib
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STAGED = ROOT / "samples" / "_staged"
BASE = "https://fate-suite.ffmpeg.org/"

# (fate path, format dir, pinned sha256 — TOFU then freeze)
# Tier-3 five: TOFU'd 2026-07-17. Wave C ten: TOFU'd 2026-08-16, frozen.
# Wave D ten: TOFU'd 2026-08-16, frozen.
HEADS = [
    ("smacker/wetlogo.smk", "smk",
     "dfba9d646f0889f073edb3c3241115f92b4c84f5c567da3e0f5bc7900f646c49"),
    ("bink/RazOnBull.bik", "bink",
     "c803f82c05d7be97cd57be372ba302529717c95640650eefcc1dcb5cf76e6458"),
    ("vqa/small-cut-v3.vqa", "wsvqa",
     "4e2cff423b0e6bdaf70e5e44327d3ee0de03e686a7deee20f7541ccc47803d68"),
    ("interplay-mve/descent3-level5-16bit-partial.mve", "ipmovie",
     "d0dcedcfd18385ed18e57fd30a83de23f36d3745377f140df90dd873c7610469"),
    ("fli/jj00c2.fli", "flic",
     "41038fd05f38115350c4ba09cf05fb20b8f3bc3cc6538b74e23ea4b12499e1a6"),
    ("thp/pikmin2-opening1-partial.thp", "thp",
     "b3a1fbf33c8fbd005bcd146d1d2794fe05d51dd9b6ac5bfaa546d7499182386f"),
    ("xmv/logos1p.fmv", "xmv",
     "e038ce40e73e449ae9a729db3132e59a23e75af0a2f2471315ccf5e4814865b3"),
    ("smush/ronin_part.znm", "smush",
     "b76a9dd66a77f8b4bf81c92df2dc45cc2a403067c39463adde46c0ddffc9e9a8"),
    ("vmd/12.vmd", "vmd",
     "1ed09ce9804a08b964a1b63cbef9327df690983663c26be7973541de786ccf57"),
    ("idcin/idlog-2MB.cin", "idcin",
     "92f29679c92c35aa908c1237e4d4586a83c2e1d23e02c3006b2fc523406bb9e5"),
    ("wc3movie/SC_32-part.MVE", "wc3",
     "335f0896af05a109e01096bd19f65d1e185d2c622f4e02a148734ac5c0b5eb4b"),
    ("4xm/version1.4xm", "4xm",
     "b8326c1eb42b13eb645a2ed68ec9f0e01dca3551e895520837f530946f57cebf"),
    ("yop/test1.yop", "yop",
     "9556f42dfee0f982ea962c37e601d3bc55149bf834a998ea827777a157c8a323"),
    ("brstm/lozswd_partial.brstm", "brstm",
     "5c90dc6ad3e0ed89402c422570ae0d836518557d944bcf77b5a29712b16d551d"),
    ("psx-str/abc000_cut.str", "psxstr",
     "681df9dd0a50fccdd55553c1fa6b985fc47b3ea0177d18848158134944dab0a8"),
    ("paf/hod1-partial.paf", "paf",
     "43215ae789d636ca6557dd0eeca0c34121860ce3ad72562041e6da14ba07a0e8"),
    ("dxa/scummvm.dxa", "dxa",
     "40f21a2327e546cfc696019179c60f19375fadbf3b0cebee26554f9e5a90c178"),
    ("bmv/SURFING-partial.BMV", "bmv",
     "29b505e6f0054602be0933a639bc58ab1567310481b3926cf6dfa0b055173d46"),
    ("cyberia-c93/intro1.c93", "c93",
     "751f98f4bdd00c3e7570ce72a9f3a09b55a6188758d917db041cd2ddb928ccc1"),
    ("sol/lsl7sample.sol", "sol",
     "19f778c41091bfe4a7ac3fb74540aadfb5e2ccb0085238e3042b78aeac09f936"),
    ("SIFF/INTRO_B.VB", "siff",
     "034bc27bce8ffdb5413e1f5cef8471a7f021c6e28f59a6e9d307e56844550bea"),
    ("bethsoft-vid/ANIM0001.VID", "bethsoftvid",
     "7bce340fba63beb614802904a514294f896f196031d7ae1a698dfca61e422938"),
    ("delphine-cin/LOGO-partial.CIN", "dsicin",
     "ac8c01d89d484ab3a61761aa465350ca4c1b56bf4ea59f8dc0572873f25bbc7e"),
    ("maxis-xa/SC2KBUG.XA", "xa",
     "9d68e3b081a824a0d81ff71503c7e83bafd6a00f7bab8b762a99f442f8cfb05e"),
    ("bfstm/spl-forest-day.bfstm", "bfstm",
     "0a892a3833e81b91a28444ca66f9ebc844db990490f12cf0760db224100a9332"),
]


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "palimpsest-stage/1"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.read()


def upstream_md5(dirname: str, filename: str) -> str | None:
    try:
        listing = fetch(BASE + dirname + "/md5sum").decode("utf-8", "replace")
    except Exception:  # noqa: BLE001 — md5sum file is best-effort provenance
        return None
    for line in listing.splitlines():
        parts = line.split()
        if len(parts) >= 2 and parts[-1].lstrip("*").endswith(filename):
            return parts[0]
    return None


def main() -> None:
    failures = 0
    for fate_path, fmt, pinned in HEADS:
        dirname, filename = fate_path.split("/", 1)
        payload = fetch(BASE + fate_path)
        sha = hashlib.sha256(payload).hexdigest()
        md5 = hashlib.md5(payload).hexdigest()
        want_md5 = upstream_md5(dirname, filename)
        md5_ok = (want_md5 is None) or (md5 == want_md5)
        pin_ok = (pinned is None) or (sha == pinned)
        if not md5_ok:
            print(f"FAIL {fate_path}: md5 {md5} != upstream {want_md5}")
            failures += 1
            continue
        if not pin_ok:
            print(f"FAIL {fate_path}: sha256 drift vs pinned {pinned}")
            failures += 1
            continue
        dest = STAGED / fmt / filename
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(payload)
        tofu = " (TOFU - pin this sha256)" if pinned is None else ""
        up = "upstream-md5 ok" if want_md5 else "no upstream md5"
        print(f"ok   {fmt}: {filename} {len(payload)} bytes sha256 {sha} [{up}]{tofu}")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
