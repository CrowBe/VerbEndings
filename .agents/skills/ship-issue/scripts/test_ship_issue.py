#!/usr/bin/env python3
"""Deterministic unit tests for ship_issue.py."""

from __future__ import annotations

import importlib.util
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).with_name("ship_issue.py")
SPEC = importlib.util.spec_from_file_location("ship_issue", SCRIPT)
assert SPEC and SPEC.loader
SHIP = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SHIP)


class ShipIssueTests(unittest.TestCase):
    def test_git_preserves_leading_status_column(self) -> None:
        completed = SHIP.subprocess.CompletedProcess(
            args=["git"], returncode=0, stdout=" M tracked-file\n", stderr=""
        )
        with patch.object(SHIP, "run_command", return_value=completed):
            self.assertEqual(SHIP.git(Path("."), "status", "--short"), " M tracked-file")

    def test_repo_view_uses_positional_repository(self) -> None:
        completed = SHIP.subprocess.CompletedProcess(
            args=["gh"], returncode=0, stdout="{}\n", stderr=""
        )
        with patch.object(SHIP, "run_command", return_value=completed) as runner:
            SHIP.gh("owner/repository", "repo", "view", "--json", "url")
        self.assertEqual(
            runner.call_args.args[0],
            ("gh", "repo", "view", "owner/repository", "--json", "url"),
        )

    def test_outputs_are_restricted_to_temporary_directory(self) -> None:
        with self.assertRaisesRegex(ValueError, "must be inside"):
            SHIP.temporary_output_path("/var/tmp/not-the-system-temp/report.json")
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / "report.json"
            self.assertEqual(SHIP.temporary_output_path(str(destination)), destination)

    def test_fingerprint_detects_changes_to_already_dirty_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            dirty_file = repo / "already-dirty.txt"
            dirty_file.write_text("first version", encoding="utf-8")
            first = SHIP.fingerprint_path(repo, "already-dirty.txt")
            dirty_file.write_text("second version", encoding="utf-8")
            second = SHIP.fingerprint_path(repo, "already-dirty.txt")
        self.assertNotEqual(first["sha256"], second["sha256"])

    def test_parse_github_remote(self) -> None:
        cases = {
            "git@github.com:owner/repository.git": "owner/repository",
            "https://github.com/owner/repository.git": "owner/repository",
            "ssh://git@github.com/owner/repository.git": "owner/repository",
        }
        for remote, expected in cases.items():
            with self.subTest(remote=remote):
                self.assertEqual(SHIP.parse_github_remote(remote), expected)
        self.assertIsNone(SHIP.parse_github_remote("https://example.com/a/b.git"))

    def test_parse_worktrees(self) -> None:
        raw = """worktree /repo
HEAD abc123
branch refs/heads/main

worktree /repo-feature
HEAD def456
branch refs/heads/feature
locked
"""
        self.assertEqual(
            SHIP.parse_worktrees(raw),
            [
                {"worktree": "/repo", "HEAD": "abc123", "branch": "refs/heads/main"},
                {
                    "worktree": "/repo-feature",
                    "HEAD": "def456",
                    "branch": "refs/heads/feature",
                    "locked": True,
                },
            ],
        )

    def test_issue_inventory_matches_closing_references_and_branches(self) -> None:
        issues = [
            {
                "number": 9,
                "title": "Improve entry",
                "url": "https://example/issues/9",
                "labels": [{"name": "priority:high"}],
                "milestone": {"title": "Alpha"},
                "assignees": [{"login": "dev"}],
                "updatedAt": "2026-08-12T00:00:00Z",
                "blockedBy": [{"number": 3}],
                "blocking": [],
            }
        ]
        pulls = [
            {
                "number": 64,
                "title": "Improve entry",
                "url": "https://example/pulls/64",
                "headRefName": "agent/issue-9-entry",
                "isDraft": True,
                "closingIssuesReferences": [{"number": 9}],
            }
        ]
        inventory = SHIP.build_issue_inventory(
            issues, pulls, ["origin/main", "origin/agent/issue-9-entry"]
        )
        self.assertEqual(inventory[0]["blocked_by"], [3])
        self.assertEqual(inventory[0]["pulls"][0]["number"], 64)
        self.assertEqual(
            inventory[0]["matching_remote_branches"],
            ["origin/agent/issue-9-entry"],
        )

    def test_check_summary_requires_nonempty_terminal_success(self) -> None:
        self.assertFalse(SHIP.check_summary([])["terminal"])
        summary = SHIP.check_summary(
            [
                {"name": "validate", "bucket": "pass"},
                {"name": "optional", "bucket": "skipping"},
            ]
        )
        self.assertTrue(summary["terminal"])
        self.assertTrue(summary["successful"])
        failed = SHIP.check_summary([{"name": "test", "bucket": "fail"}])
        self.assertTrue(failed["terminal"])
        self.assertFalse(failed["successful"])

    def test_check_labels_distinguish_duplicate_job_names(self) -> None:
        summary = SHIP.check_summary(
            [
                {"name": "validate", "workflow": "Static", "bucket": "pass"},
                {"name": "validate", "workflow": "Godot", "bucket": "pass"},
            ]
        )
        self.assertEqual(
            summary["buckets"]["pass"],
            ["Godot: validate", "Static: validate"],
        )

    def test_check_labels_distinguish_duplicate_workflow_jobs(self) -> None:
        summary = SHIP.check_summary(
            [
                {
                    "name": "validate",
                    "workflow": "Validation",
                    "link": "https://example/runs/2",
                    "bucket": "pass",
                },
                {
                    "name": "validate",
                    "workflow": "Validation",
                    "link": "https://example/runs/1",
                    "bucket": "pass",
                },
            ]
        )
        self.assertEqual(
            summary["buckets"]["pass"],
            ["Validation: validate [1/2]", "Validation: validate [2/2]"],
        )

    def test_render_pr_body_has_one_closing_reference(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            report = Path(directory) / "verification.md"
            report.write_text("Verdict: PASS\n", encoding="utf-8")
            args = Namespace(
                issue=9,
                summary=["Improve the entry layout", "Add regression coverage"],
                verification_report=str(report),
                human_review=["Confirm subjective camera comfort"],
            )
            body = SHIP.render_pr_body(args)
        self.assertEqual(body.count("Closes #9"), 1)
        self.assertIn("Verdict: PASS", body)
        self.assertIn("## Human review", body)

    def test_readiness_distinguishes_draft_and_ready(self) -> None:
        pr = {
            "state": "OPEN",
            "isDraft": True,
            "baseRefName": "main",
            "headRefName": "agent/issue-9-entry",
            "headRefOid": "abc123",
            "closingIssuesReferences": [{"number": 9}],
        }
        checks = {"count": 1, "terminal": True, "successful": True}
        evaluation = SHIP.evaluate_readiness(
            pr,
            checks,
            issue=9,
            base="main",
            expected_head="abc123",
            local_head="abc123",
            current_branch_name="agent/issue-9-entry",
            status_matches=True,
        )
        self.assertTrue(evaluation["ready_to_mark"])
        self.assertFalse(evaluation["complete"])
        pr["isDraft"] = False
        evaluation = SHIP.evaluate_readiness(
            pr,
            checks,
            issue=9,
            base="main",
            expected_head="abc123",
            local_head="abc123",
            current_branch_name="agent/issue-9-entry",
            status_matches=True,
        )
        self.assertTrue(evaluation["complete"])

    def test_readiness_reports_every_failed_invariant(self) -> None:
        evaluation = SHIP.evaluate_readiness(
            {
                "state": "CLOSED",
                "isDraft": True,
                "baseRefName": "develop",
                "headRefName": "other",
                "headRefOid": "old",
                "closingIssuesReferences": [],
            },
            {"count": 0, "terminal": False, "successful": False},
            issue=9,
            base="main",
            expected_head="new",
            local_head="new",
            current_branch_name="agent/issue-9-entry",
            status_matches=False,
        )
        self.assertGreaterEqual(len(evaluation["failures"]), 6)
        self.assertFalse(evaluation["ready_to_mark"])


if __name__ == "__main__":
    unittest.main()
