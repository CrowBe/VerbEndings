#!/usr/bin/env python3
"""Static validation for the Godot project layout.

This is intentionally engine-light: it catches missing main scenes and broken
resource paths in text scenes/scripts before a full Godot or Summer Engine smoke
test runs. Runtime validation should still be done in Summer Engine/Godot when a
binary is available.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESOURCE_RE = re.compile(r'(?:path|script|mesh|shape)="(res://[^"]+)"')
PRELOAD_RE = re.compile(r'preload\("(res://[^"]+)"\)')
LOAD_RE = re.compile(r'load\("(res://[^"]+)"\)')


def res_to_path(resource: str) -> Path:
    if not resource.startswith("res://"):
        raise ValueError(f"Not a Godot res:// path: {resource}")
    return ROOT / resource.removeprefix("res://")


def project_main_scene() -> str:
    in_application = False
    for raw_line in (ROOT / "project.godot").read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line == "[application]":
            in_application = True
            continue
        if line.startswith("[") and line.endswith("]"):
            in_application = False
        if in_application and line.startswith("run/main_scene="):
            return line.split("=", 1)[1].strip().strip('"')
    return ""


def referenced_resources(path: Path) -> set[str]:
    text = path.read_text(encoding="utf-8")
    resources = set(RESOURCE_RE.findall(text))
    resources.update(PRELOAD_RE.findall(text))
    resources.update(LOAD_RE.findall(text))
    return resources


def main() -> int:
    errors: list[str] = []

    main_scene = project_main_scene()
    if not main_scene:
        errors.append("project.godot is missing application/run/main_scene")
    elif not res_to_path(main_scene).is_file():
        errors.append(f"main scene does not exist: {main_scene}")

    for path in sorted(ROOT.rglob("*")):
        if path.suffix not in {".tscn", ".gd"}:
            continue
        for resource in sorted(referenced_resources(path)):
            target = res_to_path(resource)
            if not target.exists():
                errors.append(f"{path.relative_to(ROOT)} references missing {resource}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"Validated main scene and resource references for {ROOT.name}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
