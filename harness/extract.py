#!/usr/bin/env python3
"""Parse a sample with a compiled Kaitai parser and print sidecar fields.

Usage: extract.py <build_dir> <module_name> <sample> <fields.json>

Prints one `name=value` line per oracle field (attribute-chain resolution
per the sidecar's kaitai_path). Exit non-zero on any resolution failure.
Part of the frozen harness (DESIGN.md § 3).
"""

import importlib.util
import json
import sys
from pathlib import Path


def camel(module_name: str) -> str:
    return "".join(part.capitalize() for part in module_name.split("_"))


def main() -> int:
    build_dir, module_name, sample, sidecar = sys.argv[1:5]
    spec = importlib.util.spec_from_file_location(
        module_name, Path(build_dir) / f"{module_name}.py"
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    cls = getattr(mod, camel(module_name))
    parsed = cls.from_file(sample)

    fields = json.loads(Path(sidecar).read_text(encoding="utf-8"))["fields"]
    for field in fields:
        obj = parsed
        for part in field["kaitai_path"].split("."):
            obj = getattr(obj, part)
        if isinstance(obj, bytes):
            obj = obj.decode("ascii", "replace")
        print(f"{field['name']}={obj}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
