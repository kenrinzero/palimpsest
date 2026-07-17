#!/usr/bin/env python3
"""Tier-3 prep — stage the five decode-only head-format samples.

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

# (fate path, format dir, pinned sha256 — TOFU'd 2026-07-17, now frozen)
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
