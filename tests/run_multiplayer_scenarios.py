#!/usr/bin/env python3
"""Run deterministic scale checks and the real ENet Trial scenarios."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import time


MARKER = "MULTIPLAYER_SCALE_SCENARIO "
ERROR_MARKERS = ("ERROR:", "SCRIPT ERROR", "Parse Error", "WARNING:")


def _run_scale_scenario(
    godot: str,
    mode: str,
    subject_count: int,
    seed: int,
    collapse: bool,
    timeout_seconds: float,
) -> tuple[dict[str, object], float]:
    command = [
        godot,
        "--headless",
        "--path",
        ".",
        "tests/TestMultiplayerScaleScenario.tscn",
        "--",
        f"--mode={mode}",
        f"--subject-count={subject_count}",
        f"--seed={seed}",
    ]
    if collapse:
        command.append("--collapse")
    started = time.monotonic()
    completed = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=timeout_seconds,
        check=False,
    )
    duration = round(time.monotonic() - started, 3)
    print(completed.stdout, end="")
    if completed.returncode != 0:
        raise RuntimeError(
            f"{mode} {subject_count}-Subject scenario exited "
            f"with status {completed.returncode}"
        )
    if any(marker.lower() in completed.stdout.lower() for marker in ERROR_MARKERS):
        raise RuntimeError(f"{mode} {subject_count}-Subject scenario logged an error")
    for line in completed.stdout.splitlines():
        if line.startswith(MARKER):
            return json.loads(line.removeprefix(MARKER)), duration
    raise RuntimeError(f"{mode} {subject_count}-Subject scenario omitted its digest")


def _run_network_scenarios(
    godot: str, seed: int, timeout_seconds: float
) -> dict[str, object]:
    command = [
        sys.executable,
        str(Path("tests/run_network_session_test.py")),
        "--godot",
        godot,
        "--seed",
        str(seed),
        "--timeout-seconds",
        str(timeout_seconds),
    ]
    completed = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=timeout_seconds * 3,
        check=False,
    )
    print(completed.stdout, end="")
    if completed.returncode != 0:
        raise RuntimeError(
            f"real ENet scenarios exited with status {completed.returncode}"
        )
    for line in completed.stdout.splitlines():
        if line.startswith("NETWORK_SESSION_SUMMARY "):
            return json.loads(line.removeprefix("NETWORK_SESSION_SUMMARY "))
    raise RuntimeError("real ENet scenarios omitted their summary")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot4.3")
    parser.add_argument("--seed", type=int, default=24680)
    parser.add_argument("--timeout-seconds", type=float, default=30.0)
    args = parser.parse_args()
    specifications = [
        ("lifecycle", 8, False),
        ("lifecycle", 9, True),
        ("capacity", 12, False),
        ("capacity", 24, False),
    ]
    results: list[dict[str, object]] = []
    try:
        for mode, subject_count, collapse in specifications:
            first, first_duration = _run_scale_scenario(
                args.godot,
                mode,
                subject_count,
                args.seed,
                collapse,
                args.timeout_seconds,
            )
            second, second_duration = _run_scale_scenario(
                args.godot,
                mode,
                subject_count,
                args.seed,
                collapse,
                args.timeout_seconds,
            )
            if first != second:
                raise RuntimeError(
                    f"seeded {mode} {subject_count}-Subject digests diverged"
                )
            results.append(
                {
                    "mode": mode,
                    "subject_count": subject_count,
                    "deterministic": True,
                    "durations_seconds": [first_duration, second_duration],
                    "digest": first,
                }
            )
        network = _run_network_scenarios(
            args.godot, args.seed, args.timeout_seconds
        )
    except (OSError, subprocess.TimeoutExpired, RuntimeError, json.JSONDecodeError) as error:
        print(f"multiplayer scenario runner failed: {error}", file=sys.stderr)
        return 1
    print(
        "MULTIPLAYER_SCENARIOS_SUMMARY "
        + json.dumps(
            {"seed": args.seed, "synthetic": results, "real_enet": network},
            sort_keys=True,
        )
    )
    print("Multiplayer scenario tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
