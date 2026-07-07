#!/usr/bin/env bash
# Frozen encodable-tail sample recipes (DESIGN.md § 6). Generated samples
# are COMMITTED with sha256 in samples/SOURCES.md — regeneration is a
# deliberate unit, never a side effect (an ffmpeg upgrade must not silently
# rewrite the corpus).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/samples/au" "$ROOT/samples/voc" "$ROOT/samples/roq"

ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "sine=frequency=440:duration=1" -ar 8000 -ac 1 \
  "$ROOT/samples/au/sine.au"
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "sine=frequency=440:duration=1" -ar 11025 -ac 1 \
  "$ROOT/samples/voc/sine.voc"
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "testsrc=size=64x64:duration=1:rate=15" \
  "$ROOT/samples/roq/test.roq"
ls -la "$ROOT"/samples/*/
