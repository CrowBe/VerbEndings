#!/usr/bin/env python3
"""Run the environment kit rebuild scene and reject Godot diagnostics."""

from __future__ import annotations

import argparse
import ctypes
import math
import os
import signal
import subprocess
import sys
from collections.abc import Sequence
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from time import monotonic, sleep
from typing import Iterator


SUCCESS_MARKER = "Environment kit piece rebuild tests passed."
FORBIDDEN_OUTPUT = (
    "ERROR:",
    "SCRIPT ERROR:",
    "Parse Error:",
    "WARNING:",
)
DEFAULT_TIMEOUT_SECONDS = 30.0
TERMINATION_GRACE_SECONDS = 3.0
PROCESS_REAP_POLL_SECONDS = 0.01
PR_SET_CHILD_SUBREAPER = 36
PR_GET_CHILD_SUBREAPER = 37


@dataclass(frozen=True)
class AttemptResult:
    returncode: int | None
    stdout: str
    stderr: str
    timed_out: bool
    termination_signal: int | None = None
    cleanup_error: str | None = None

    @property
    def output(self) -> str:
        return self.stdout + self.stderr


@dataclass(frozen=True)
class AttemptClassification:
    passed: bool
    diagnostics: tuple[str, ...]


def _positive_int(value: str) -> int:
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("must be a positive integer")
    return parsed


def _positive_float(value: str) -> float:
    parsed = float(value)
    if not math.isfinite(parsed) or parsed <= 0.0:
        raise argparse.ArgumentTypeError("must be a positive finite number")
    return parsed


def _signal_process_group(process_group_id: int, sig: signal.Signals) -> bool:
    try:
        os.killpg(process_group_id, sig)
    except ProcessLookupError:
        return False
    return True


def _process_group_exists(process_group_id: int) -> bool:
    try:
        os.killpg(process_group_id, 0)
    except ProcessLookupError:
        return False
    return True


def _prctl(option: int, argument: object) -> None:
    if not sys.platform.startswith("linux"):
        raise RuntimeError(
            "full process-tree reaping requires Linux child-subreaper support"
        )
    libc = ctypes.CDLL(None, use_errno=True)
    try:
        prctl = libc.prctl
    except AttributeError as error:
        raise RuntimeError(
            "full process-tree reaping requires Linux prctl support"
        ) from error
    ctypes.set_errno(0)
    if prctl(option, argument, 0, 0, 0) != 0:
        error_number = ctypes.get_errno()
        raise OSError(error_number, os.strerror(error_number))


def _get_child_subreaper() -> int:
    state = ctypes.c_int()
    _prctl(PR_GET_CHILD_SUBREAPER, ctypes.byref(state))
    return state.value


@contextmanager
def _child_subreaper() -> Iterator[None]:
    previous_state = _get_child_subreaper()
    _prctl(PR_SET_CHILD_SUBREAPER, 1)
    try:
        yield
    finally:
        _prctl(PR_SET_CHILD_SUBREAPER, previous_state)


def _reap_process_group(
    process_group_id: int,
    timeout_seconds: float,
) -> bool:
    deadline = monotonic() + timeout_seconds
    while True:
        while True:
            try:
                child_pid, _status = os.waitpid(
                    -process_group_id,
                    os.WNOHANG,
                )
            except ChildProcessError:
                break
            if child_pid == 0:
                break
        if not _process_group_exists(process_group_id):
            return True
        if monotonic() >= deadline:
            return False
        sleep(PROCESS_REAP_POLL_SECONDS)


def _timeout_output(output: str | bytes | None) -> str:
    if output is None:
        return ""
    if isinstance(output, bytes):
        return output.decode(errors="replace")
    return output


def run_attempt(
    command: Sequence[str],
    cwd: Path,
    timeout_seconds: float,
) -> AttemptResult:
    with _child_subreaper():
        process = subprocess.Popen(
            command,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            start_new_session=True,
        )
        try:
            stdout, stderr = process.communicate(timeout=timeout_seconds)
        except subprocess.TimeoutExpired:
            termination_signal = signal.SIGTERM
            _signal_process_group(process.pid, termination_signal)
            try:
                stdout, stderr = process.communicate(
                    timeout=TERMINATION_GRACE_SECONDS
                )
            except subprocess.TimeoutExpired:
                termination_signal = signal.SIGKILL
                _signal_process_group(process.pid, termination_signal)
                try:
                    stdout, stderr = process.communicate(
                        timeout=TERMINATION_GRACE_SECONDS
                    )
                    cleanup_error = None
                except subprocess.TimeoutExpired as error:
                    stdout = _timeout_output(error.stdout)
                    stderr = _timeout_output(error.stderr)
                    cleanup_error = (
                        "process group did not close captured output after "
                        "SIGKILL"
                    )
            else:
                cleanup_error = None
                if _process_group_exists(process.pid):
                    termination_signal = signal.SIGKILL
                    _signal_process_group(process.pid, termination_signal)
            if not _reap_process_group(
                process.pid,
                TERMINATION_GRACE_SECONDS,
            ):
                cleanup_error = (
                    "process group still existed after bounded SIGKILL "
                    "reaping"
                )
            return AttemptResult(
                process.returncode,
                stdout,
                stderr,
                True,
                termination_signal,
                cleanup_error,
            )
        return AttemptResult(process.returncode, stdout, stderr, False)


def classify_attempt(result: AttemptResult) -> AttemptClassification:
    diagnostics = tuple(
        line
        for line in result.output.splitlines()
        if any(token in line for token in FORBIDDEN_OUTPUT)
    )
    return AttemptClassification(
        not result.timed_out
        and result.returncode == 0
        and SUCCESS_MARKER in result.output
        and not diagnostics,
        diagnostics,
    )


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot4.3")
    parser.add_argument("--attempts", type=_positive_int, default=2)
    parser.add_argument(
        "--timeout-seconds",
        type=_positive_float,
        default=DEFAULT_TIMEOUT_SECONDS,
        help="positive wall-clock limit for each Godot attempt",
    )
    arguments = parser.parse_args(argv)
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
        result = run_attempt(
            command,
            project_root,
            arguments.timeout_seconds,
        )
        sys.stdout.write(
            f"Attempt {attempt}/{arguments.attempts}\n{result.output}"
        )
        classification = classify_attempt(result)
        if result.timed_out:
            signal_name = (
                signal.Signals(result.termination_signal).name
                if result.termination_signal is not None
                else "unknown signal"
            )
            sys.stderr.write(
                f"Attempt {attempt} timed out after "
                f"{arguments.timeout_seconds:g} seconds; "
                f"terminated process group with {signal_name} and reaped "
                "its child process tree.\n"
            )
            if result.cleanup_error is not None:
                sys.stderr.write(
                    f"Attempt {attempt} cleanup failed: "
                    f"{result.cleanup_error}.\n"
                )
        if not classification.passed:
            failed = True
            sys.stderr.write(
                f"Attempt {attempt} failed: exit={result.returncode}, "
                f"timed_out={result.timed_out}, "
                f"success_marker={SUCCESS_MARKER in result.output}, "
                f"diagnostics={list(classification.diagnostics)!r}\n"
            )
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
