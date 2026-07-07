#!/usr/bin/env bash
# One-time portable toolchain provisioning (DESIGN.md § 1). Re-runnable;
# skips components already present. Needs web; no sudo.
set -euo pipefail
KAITAI_HOME="${KAITAI_HOME:-$HOME/opt/kaitai}"
mkdir -p "$KAITAI_HOME"
cd "$KAITAI_HOME"

if [ ! -d jre ]; then
  echo "fetching Temurin 21 JRE (linux x64)..."
  curl -fsSL -o jre.tar.gz \
    "https://api.adoptium.net/v3/binary/latest/21/ga/linux/x64/jre/hotspot/normal/eclipse"
  mkdir jre && tar -xzf jre.tar.gz -C jre --strip-components=1 && rm jre.tar.gz
fi
./jre/bin/java -version

if [ ! -d compiler ]; then
  for v in 0.11 0.10; do
    echo "trying kaitai-struct-compiler $v..."
    if curl -fsSL -o ksc.zip \
      "https://github.com/kaitai-io/kaitai_struct_compiler/releases/download/$v/kaitai-struct-compiler-$v.zip"; then
      break
    fi
  done
  python3 -c "import zipfile; zipfile.ZipFile('ksc.zip').extractall('.')"
  mv kaitai-struct-compiler-* compiler
  chmod +x compiler/bin/kaitai-struct-compiler
  rm ksc.zip
fi
JAVA_HOME="$KAITAI_HOME/jre" PATH="$KAITAI_HOME/jre/bin:$PATH" \
  compiler/bin/kaitai-struct-compiler --version
echo "provisioned at $KAITAI_HOME"
