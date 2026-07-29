#!/usr/bin/env python3
"""Run the environment kit rebuild scene and reject Godot diagnostics."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


SUCCESS_MARKER = "Environment kit piece rebuild tests passed."
FORBIDDEN_OUTPUT = (
    "ERROR:",
    "SCRIPT ERROR:",
    "Parse Error:",
    "WARNING:",
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot4.3")
    parser.add_argument("--attempts", type=int, default=2)
    arguments = parser.parse_args()
    project_root = Path(__file__).resolve().parents[1]
    command = [
        arguments.godot,
        "--headless",
        "--path",
        str(project_root),
        "tests/TestEnvironmentKitPieceRebuild.tscn",
    ]
    failed = False
    for attempt in range(1, arguments.attempts + 1):
        result = subprocess.run(
            command,
            cwd=project_root,
            capture_output=True,
            text=True,
            check=False,
        )
        output = result.stdout + result.stderr
        sys.stdout.write(f"Attempt {attempt}/{arguments.attempts}\n{output}")
        diagnostics = [
            line for line in output.splitlines()
            if any(token in line for token in FORBIDDEN_OUTPUT)
        ]
        if (
            result.returncode != 0
            or SUCCESS_MARKER not in output
            or diagnostics
        ):
            failed = True
            sys.stderr.write(
                f"Attempt {attempt} failed: exit={result.returncode}, "
                f"success_marker={SUCCESS_MARKER in output}, "
                f"diagnostics={diagnostics!r}\n"
            )
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
