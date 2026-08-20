#!/usr/bin/env python3
"""Build and smoke-test the supported Godot 4.3 playtest export."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = Path("build/linux/VerbEndings.x86_64")
DIAGNOSTIC_PATTERN = re.compile(
    r"(^|\s)(SCRIPT ERROR|ERROR:|Parse Error|WARNING:)", re.IGNORECASE
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export and launch-smoke the supported Linux playtest build."
    )
    parser.add_argument("--godot", default="godot4.3", help="Godot 4.3 executable")
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help="output executable path, relative to the repository by default",
    )
    parser.add_argument(
        "--smoke-seconds",
        type=float,
        default=5.0,
        help="seconds the exported main menu must remain running",
    )
    return parser.parse_args()


def run_checked(command: list[str], label: str) -> str:
    completed = subprocess.run(
        command,
        cwd=PROJECT_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    output = completed.stdout
    if output:
        print(output, end="")
    if completed.returncode != 0:
        raise RuntimeError(f"{label} exited with status {completed.returncode}")
    reject_diagnostics(output, label)
    return output


def reject_diagnostics(output: str, label: str) -> None:
    matches = [line for line in output.splitlines() if DIAGNOSTIC_PATTERN.search(line)]
    if matches:
        raise RuntimeError(f"{label} reported diagnostics: {matches!r}")


def smoke_export(executable: Path, seconds: float) -> None:
    process = subprocess.Popen(
        [str(executable), "--headless", "--no-header"],
        cwd=executable.parent,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    try:
        output, _ = process.communicate(timeout=seconds)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGINT)
        try:
            output, _ = process.communicate(timeout=3.0)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            output, _ = process.communicate(timeout=3.0)
    else:
        if output:
            print(output, end="")
        raise RuntimeError(
            f"exported build exited before the {seconds:.1f}s smoke window "
            f"(status {process.returncode})"
        )
    if output:
        print(output, end="")
    reject_diagnostics(output, "exported build smoke check")


def main() -> int:
    args = parse_args()
    if args.smoke_seconds <= 0:
        raise ValueError("--smoke-seconds must be positive")
    godot = shutil.which(args.godot)
    if godot is None:
        raise FileNotFoundError(f"Godot executable not found: {args.godot}")
    version = run_checked([godot, "--version"], "Godot version check").strip()
    if not version.startswith("4.3"):
        raise RuntimeError(f"Godot 4.3 is required; found {version!r}")

    output = args.output
    if not output.is_absolute():
        output = PROJECT_ROOT / output
    output.parent.mkdir(parents=True, exist_ok=True)
    run_checked(
        [
            godot,
            "--headless",
            "--path",
            str(PROJECT_ROOT),
            "--export-release",
            "Linux x86_64",
            str(output),
        ],
        "Godot release export",
    )
    package = output.with_suffix(".pck")
    missing = [str(path) for path in (output, package) if not path.is_file()]
    if missing:
        raise RuntimeError(f"export did not produce expected files: {missing!r}")
    runbook = output.parent / "PLAYTEST.md"
    shutil.copyfile(PROJECT_ROOT / "docs/PLAYTEST.md", runbook)
    output.chmod(output.stat().st_mode | 0o111)
    smoke_export(output, args.smoke_seconds)
    shown_output = output.relative_to(PROJECT_ROOT) \
        if output.is_relative_to(PROJECT_ROOT) else output
    print(f"Export check passed: {shown_output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (FileNotFoundError, RuntimeError, ValueError) as error:
        print(f"Export check failed: {error}", file=sys.stderr)
        raise SystemExit(1)
