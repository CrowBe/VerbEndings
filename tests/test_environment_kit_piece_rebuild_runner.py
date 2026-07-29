#!/usr/bin/env python3
"""Focused tests for the environment-kit rebuild subprocess runner."""

from __future__ import annotations

import io
import os
import signal
import sys
import time
import unittest
from pathlib import Path
from unittest import mock


sys.path.insert(0, str(Path(__file__).resolve().parent))

import run_environment_kit_piece_rebuild_test as runner


class EnvironmentKitPieceRebuildRunnerTests(unittest.TestCase):
    def test_timeout_reaps_child_and_rejects_early_success_marker(self) -> None:
        grandchild_code = "\n".join(
            (
                "import signal",
                "import time",
                "signal.signal(signal.SIGTERM, signal.SIG_IGN)",
                "time.sleep(60)",
            )
        )
        child_code = "\n".join(
            (
                "import os",
                "import signal",
                "import subprocess",
                "import sys",
                "import time",
                "signal.signal(signal.SIGTERM, signal.SIG_IGN)",
                "grandchild = subprocess.Popen("
                f"[sys.executable, '-c', {grandchild_code!r}])",
                f"print({runner.SUCCESS_MARKER!r})",
                "print(f'child_pid={os.getpid()}')",
                "print(f'grandchild_pid={grandchild.pid}')",
                "sys.stdout.flush()",
                "time.sleep(60)",
            )
        )

        result = runner.run_attempt(
            [sys.executable, "-c", child_code],
            Path.cwd(),
            timeout_seconds=0.2,
        )

        self.assertTrue(result.timed_out)
        self.assertIn(runner.SUCCESS_MARKER, result.output)
        self.assertFalse(runner.classify_attempt(result).passed)
        for prefix in ("child_pid=", "grandchild_pid="):
            process_id = int(
                next(
                    line.removeprefix(prefix)
                    for line in result.output.splitlines()
                    if line.startswith(prefix)
                )
            )
            deadline = time.monotonic() + 2.0
            while time.monotonic() < deadline:
                try:
                    os.kill(process_id, 0)
                except ProcessLookupError:
                    break
                time.sleep(0.01)
            else:
                self.fail(f"timed-out process remained alive: {process_id}")

    def test_classification_rejects_exit_marker_and_diagnostic_failures(
        self,
    ) -> None:
        cases = (
            runner.AttemptResult(1, runner.SUCCESS_MARKER, "", False),
            runner.AttemptResult(0, "", "", False),
            runner.AttemptResult(
                0,
                runner.SUCCESS_MARKER,
                "WARNING: teardown warning",
                False,
            ),
            runner.AttemptResult(0, runner.SUCCESS_MARKER, "", True),
        )

        for result in cases:
            with self.subTest(result=result):
                self.assertFalse(runner.classify_attempt(result).passed)

        passing = runner.AttemptResult(
            0,
            runner.SUCCESS_MARKER,
            "",
            False,
        )
        self.assertTrue(runner.classify_attempt(passing).passed)

    def test_invalid_limits_are_rejected_before_spawning(self) -> None:
        for option, value in (
            ("--attempts", "0"),
            ("--timeout-seconds", "0"),
            ("--timeout-seconds", "nan"),
        ):
            with self.subTest(option=option, value=value):
                with mock.patch.object(runner, "run_attempt") as run_attempt:
                    with self.assertRaises(SystemExit):
                        with mock.patch("sys.stderr", new=io.StringIO()):
                            runner.main([option, value])
                    run_attempt.assert_not_called()

    def test_failed_attempt_does_not_prevent_later_attempt(self) -> None:
        timed_out = runner.AttemptResult(
            -signal.SIGKILL,
            runner.SUCCESS_MARKER,
            "",
            True,
        )
        passed = runner.AttemptResult(0, runner.SUCCESS_MARKER, "", False)
        with mock.patch.object(
            runner,
            "run_attempt",
            side_effect=(timed_out, passed),
        ) as run_attempt:
            stdout = io.StringIO()
            stderr = io.StringIO()
            with mock.patch("sys.stdout", new=stdout):
                with mock.patch("sys.stderr", new=stderr):
                    status = runner.main(
                        [
                            "--godot",
                            "unused-godot",
                            "--attempts",
                            "2",
                            "--timeout-seconds",
                            "1",
                        ]
                    )

        self.assertEqual(status, 1)
        self.assertEqual(run_attempt.call_count, 2)
        self.assertIn(runner.SUCCESS_MARKER, stdout.getvalue())
        self.assertIn("timed out after 1 seconds", stderr.getvalue())
        self.assertIn("success_marker=True", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
