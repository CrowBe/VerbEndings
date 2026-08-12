#!/usr/bin/env python3
"""Read-only, token-efficient helpers for the ship-issue workflow."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
import tempfile
import time
from collections import Counter
from pathlib import Path
from typing import Any, Iterable, Sequence


EXIT_FAILED = 1
EXIT_USAGE_OR_TOOL = 2
EXIT_PENDING = 8
EXIT_STALE = 9


class CommandError(RuntimeError):
    def __init__(self, command: Sequence[str], returncode: int, stderr: str):
        self.command = list(command)
        self.returncode = returncode
        self.stderr = stderr.strip()
        super().__init__(
            f"command failed ({returncode}): {' '.join(command)}"
            + (f": {self.stderr}" if self.stderr else "")
        )


def run_command(
    command: Sequence[str],
    *,
    cwd: Path | None = None,
    allowed_codes: Iterable[int] = (0,),
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        list(command),
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode not in set(allowed_codes):
        raise CommandError(command, result.returncode, result.stderr)
    return result


def git(repo: Path, *args: str, allowed_codes: Iterable[int] = (0,)) -> str:
    return run_command(
        ("git", "-C", str(repo), *args), allowed_codes=allowed_codes
    ).stdout.rstrip()


def gh(repo_slug: str, *args: str, allowed_codes: Iterable[int] = (0,)) -> str:
    if args[:2] == ("repo", "view"):
        command = ("gh", "repo", "view", repo_slug, *args[2:])
    else:
        command = ("gh", *args, "-R", repo_slug)
    return run_command(command, allowed_codes=allowed_codes).stdout.strip()


def gh_json(
    repo_slug: str,
    *args: str,
    allowed_codes: Iterable[int] = (0,),
) -> Any:
    output = gh(repo_slug, *args, allowed_codes=allowed_codes)
    return json.loads(output or "null")


def emit(data: Any, *, pretty: bool = False) -> None:
    if pretty:
        print(json.dumps(data, indent=2, sort_keys=True))
    else:
        print(json.dumps(data, separators=(",", ":"), sort_keys=True))


def temporary_output_path(path: str) -> Path:
    resolved = Path(path).resolve()
    temporary_root = Path(tempfile.gettempdir()).resolve()
    if not resolved.is_relative_to(temporary_root):
        raise ValueError(f"output path must be inside {temporary_root}")
    if not resolved.parent.is_dir():
        raise ValueError(f"output directory does not exist: {resolved.parent}")
    return resolved


def resolve_repo(path: str) -> Path:
    candidate = Path(path).resolve()
    root = git(candidate, "rev-parse", "--show-toplevel")
    return Path(root)


def parse_github_remote(remote: str) -> str | None:
    remote = remote.strip()
    patterns = (
        r"^(?:https?|ssh)://(?:[^@/]+@)?github\.com[/:]([^/]+/[^/]+?)(?:\.git)?$",
        r"^(?:[^@]+@)?github\.com:([^/]+/[^/]+?)(?:\.git)?$",
    )
    for pattern in patterns:
        match = re.match(pattern, remote)
        if match:
            return match.group(1).removesuffix(".git")
    return None


def resolve_github_repo(repo: Path, override: str | None) -> str:
    if override:
        return override
    remote = git(repo, "remote", "get-url", "origin")
    slug = parse_github_remote(remote)
    if not slug:
        raise ValueError(
            "cannot derive GitHub owner/repository from origin; pass --github-repo"
        )
    return slug


def current_branch(repo: Path) -> str | None:
    branch = git(
        repo,
        "symbolic-ref",
        "--quiet",
        "--short",
        "HEAD",
        allowed_codes=(0, 1),
    )
    return branch or None


def status_lines(repo: Path) -> list[str]:
    output = git(repo, "status", "--short", "--untracked-files=all")
    return output.splitlines() if output else []


def nul_paths(output: str) -> set[str]:
    return {path for path in output.split("\0") if path}


def dirty_paths(repo: Path) -> list[str]:
    paths = nul_paths(git(repo, "diff", "--name-only", "-z"))
    paths.update(nul_paths(git(repo, "diff", "--cached", "--name-only", "-z")))
    paths.update(
        nul_paths(git(repo, "ls-files", "--others", "--exclude-standard", "-z"))
    )
    return sorted(paths)


def fingerprint_path(repo: Path, relative_path: str) -> dict[str, Any]:
    path = repo / relative_path
    if not path.exists() and not path.is_symlink():
        return {"kind": "missing"}
    stat = path.lstat()
    result: dict[str, Any] = {"mode": stat.st_mode & 0o7777}
    if path.is_symlink():
        result.update(
            {
                "kind": "symlink",
                "sha256": hashlib.sha256(path.readlink().as_posix().encode()).hexdigest(),
            }
        )
    elif path.is_file():
        result.update(
            {"kind": "file", "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
        )
    else:
        result["kind"] = "directory"
    return result


def dirty_fingerprints(repo: Path) -> dict[str, dict[str, Any]]:
    return {path: fingerprint_path(repo, path) for path in dirty_paths(repo)}


def parse_worktrees(porcelain: str) -> list[dict[str, Any]]:
    worktrees: list[dict[str, Any]] = []
    current: dict[str, Any] = {}
    for line in porcelain.splitlines() + [""]:
        if not line:
            if current:
                worktrees.append(current)
                current = {}
            continue
        key, _, value = line.partition(" ")
        if key in {"bare", "detached", "locked", "prunable"} and not value:
            current[key] = True
        else:
            current[key] = value
    return worktrees


def parse_remotes(output: str) -> list[dict[str, str]]:
    remotes: list[dict[str, str]] = []
    for line in output.splitlines():
        parts = line.split()
        if len(parts) >= 3:
            remotes.append(
                {"name": parts[0], "url": parts[1], "direction": parts[2].strip("()")}
            )
    return remotes


def compact_labels(labels: Any) -> list[str]:
    return sorted(
        item.get("name", "") for item in (labels or []) if item.get("name")
    )


def reference_numbers(references: Any) -> list[int]:
    numbers: list[int] = []
    for reference in references or []:
        number = reference.get("number") if isinstance(reference, dict) else None
        if isinstance(number, int):
            numbers.append(number)
    return sorted(set(numbers))


def preflight(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    repo = resolve_repo(args.repo)
    branch = current_branch(repo)
    head = git(repo, "rev-parse", "HEAD")
    upstream = git(
        repo,
        "rev-parse",
        "--abbrev-ref",
        "--symbolic-full-name",
        "@{upstream}",
        allowed_codes=(0, 128),
    ) or None
    ahead = behind = None
    if upstream:
        counts = git(repo, "rev-list", "--left-right", "--count", f"{upstream}...HEAD")
        left, right = counts.split()
        behind, ahead = int(left), int(right)

    result: dict[str, Any] = {
        "schema": 1,
        "repository": str(repo),
        "branch": branch,
        "head": head,
        "upstream": upstream,
        "ahead": ahead,
        "behind": behind,
        "status": status_lines(repo),
        "remotes": parse_remotes(git(repo, "remote", "-v")),
        "worktrees": parse_worktrees(git(repo, "worktree", "list", "--porcelain")),
        "recent_commits": git(
            repo, "log", "--format=%h%x09%d%x09%s", f"-{args.log_count}"
        ).splitlines(),
    }

    exit_code = 0
    if not args.offline:
        repo_slug = resolve_github_repo(repo, args.github_repo)
        result["github_repository"] = repo_slug
        try:
            repository = gh_json(
                repo_slug,
                "repo",
                "view",
                "--json",
                "nameWithOwner,url,defaultBranchRef",
            )
            pulls = []
            if branch:
                pulls = gh_json(
                    repo_slug,
                    "pr",
                    "list",
                    "--head",
                    branch,
                    "--state",
                    "all",
                    "--limit",
                    "10",
                    "--json",
                    "number,title,url,state,isDraft,baseRefName,headRefName,headRefOid",
                )
            result["github"] = {"accessible": True, "repository": repository, "pulls": pulls}
        except (CommandError, json.JSONDecodeError) as error:
            result["github"] = {"accessible": False, "error": str(error)}
            exit_code = EXIT_USAGE_OR_TOOL

    if args.save_baseline:
        baseline_path = temporary_output_path(args.save_baseline)
        fingerprints = dirty_fingerprints(repo)
        baseline = {
            "schema": 1,
            "repository": str(repo),
            "branch": branch,
            "head": head,
            "status": result["status"],
            "fingerprints": fingerprints,
        }
        baseline_path.write_text(
            json.dumps(baseline, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        result["baseline"] = str(baseline_path)
        result["dirty_fingerprint_count"] = len(fingerprints)
    return result, exit_code


def build_issue_inventory(
    issues: list[dict[str, Any]],
    pulls: list[dict[str, Any]],
    remote_branches: list[str],
) -> list[dict[str, Any]]:
    pull_issue_map: dict[int, list[dict[str, Any]]] = {}
    for pull in pulls:
        for number in reference_numbers(pull.get("closingIssuesReferences")):
            pull_issue_map.setdefault(number, []).append(pull)

    inventory: list[dict[str, Any]] = []
    for issue in issues:
        number = issue["number"]
        branch_pattern = re.compile(rf"(?:^|/)issue-{number}(?:-|$)")
        related_pulls = pull_issue_map.get(number, [])
        matching_branches = sorted(
            branch for branch in remote_branches if branch_pattern.search(branch)
        )
        inventory.append(
            {
                "number": number,
                "title": issue["title"],
                "url": issue["url"],
                "labels": compact_labels(issue.get("labels")),
                "milestone": (issue.get("milestone") or {}).get("title"),
                "assignees": sorted(
                    item.get("login", "")
                    for item in issue.get("assignees") or []
                    if item.get("login")
                ),
                "updated_at": issue.get("updatedAt"),
                "blocked_by": reference_numbers(issue.get("blockedBy")),
                "blocking": reference_numbers(issue.get("blocking")),
                "pulls": [
                    {
                        "number": pull["number"],
                        "title": pull["title"],
                        "url": pull["url"],
                        "head": pull.get("headRefName"),
                        "draft": pull.get("isDraft", False),
                    }
                    for pull in related_pulls
                ],
                "matching_remote_branches": matching_branches,
            }
        )
    return inventory


def issue_inventory(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    repo = resolve_repo(args.repo)
    repo_slug = resolve_github_repo(repo, args.github_repo)
    issues = gh_json(
        repo_slug,
        "issue",
        "list",
        "--state",
        "open",
        "--limit",
        str(args.limit),
        "--json",
        "number,title,url,labels,milestone,assignees,updatedAt,blockedBy,blocking",
    )
    pulls = gh_json(
        repo_slug,
        "pr",
        "list",
        "--state",
        "open",
        "--limit",
        str(args.limit),
        "--json",
        "number,title,url,isDraft,headRefName,baseRefName,closingIssuesReferences",
    )
    remote_branches = [
        branch.strip()
        for branch in git(repo, "branch", "-r", "--format=%(refname:short)").splitlines()
        if branch.strip() and " -> " not in branch
    ]
    inventory = build_issue_inventory(issues, pulls, remote_branches)
    return {
        "schema": 1,
        "github_repository": repo_slug,
        "issue_count": len(inventory),
        "issues": inventory,
        "note": "Read candidate issue bodies and comments before selecting; remote refs reflect the last fetch.",
    }, 0


def audit_branch(
    repo: Path,
    branch: str,
    base: str,
    current: str | None,
    checked_out: dict[str, str],
) -> dict[str, Any]:
    resolved = git(
        repo,
        "rev-parse",
        "--verify",
        f"refs/heads/{branch}",
        allowed_codes=(0, 128),
    )
    if not resolved:
        return {"branch": branch, "exists": False, "safe_to_delete": False}

    ancestor_result = run_command(
        ("git", "-C", str(repo), "merge-base", "--is-ancestor", branch, base),
        allowed_codes=(0, 1),
    )
    merged = ancestor_result.returncode == 0
    unique_count = int(git(repo, "rev-list", "--count", f"{base}..{branch}"))
    unique_commits = git(
        repo, "log", "--format=%h%x09%s", "-5", f"{base}..{branch}"
    ).splitlines()
    protections = []
    if branch == current:
        protections.append("current branch")
    if branch == base or branch in {"main", "master"}:
        protections.append("base branch")
    if branch in checked_out:
        protections.append(f"checked out at {checked_out[branch]}")
    if not merged or unique_count:
        protections.append("contains commits not in base")
    return {
        "branch": branch,
        "exists": True,
        "merged_into_base": merged,
        "unique_commit_count": unique_count,
        "unique_commits": unique_commits,
        "checked_out_at": checked_out.get(branch),
        "safe_to_delete": not protections,
        "protections": protections,
    }


def branch_audit(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    repo = resolve_repo(args.repo)
    current = current_branch(repo)
    worktrees = parse_worktrees(git(repo, "worktree", "list", "--porcelain"))
    checked_out = {
        item["branch"].removeprefix("refs/heads/"): item["worktree"]
        for item in worktrees
        if item.get("branch") and item.get("worktree")
    }
    branches = args.branches or [
        branch.strip()
        for branch in git(repo, "branch", "--format=%(refname:short)").splitlines()
        if branch.strip()
    ]
    audits = [audit_branch(repo, branch, args.base, current, checked_out) for branch in branches]
    return {
        "schema": 1,
        "base": args.base,
        "current_branch": current,
        "branches": audits,
        "safe_candidates": [item["branch"] for item in audits if item["safe_to_delete"]],
        "note": "This is advisory only; delete explicitly with git branch -d after review.",
    }, 0


def diff_summary(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    repo = resolve_repo(args.repo)
    range_args = [args.range] if args.range else []
    check = run_command(
        ("git", "-C", str(repo), "diff", "--check", *range_args),
        allowed_codes=(0, 2),
    )
    result = {
        "schema": 1,
        "range": args.range,
        "diff_check_passed": check.returncode == 0,
        "diff_check_output": check.stdout.splitlines(),
        "stat": git(repo, "diff", "--stat", *range_args).splitlines(),
        "name_status": git(repo, "diff", "--name-status", *range_args).splitlines(),
        "staged_name_status": git(repo, "diff", "--cached", "--name-status").splitlines(),
        "worktree_status": status_lines(repo),
        "note": "Inspect the complete diff separately; this summary is not a code review.",
    }
    return result, 0 if result["diff_check_passed"] else EXIT_FAILED


def render_pr_body(args: argparse.Namespace) -> str:
    verification = Path(args.verification_report).read_text(encoding="utf-8").strip()
    lines = ["## Summary", ""]
    lines.extend(f"- {item}" for item in args.summary)
    lines.extend(["", "## Verification", "", verification])
    if args.human_review:
        lines.extend(["", "## Human review", ""])
        lines.extend(f"- {item}" for item in args.human_review)
    lines.extend(["", f"Closes #{args.issue}", ""])
    return "\n".join(lines)


def pr_body(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    body = render_pr_body(args)
    destination = temporary_output_path(args.body_file)
    destination.write_text(body, encoding="utf-8")
    return {
        "schema": 1,
        "body_file": str(destination),
        "issue": args.issue,
        "summary_items": len(args.summary),
        "human_review_items": len(args.human_review),
        "contains_closing_reference": f"Closes #{args.issue}" in body,
    }, 0


def check_label(check: dict[str, Any]) -> str:
    name = check.get("name") or "unnamed"
    workflow = check.get("workflow")
    return f"{workflow}: {name}" if workflow else name


def labelled_checks(checks: list[dict[str, Any]]) -> list[tuple[str, dict[str, Any]]]:
    ordered = sorted(
        checks,
        key=lambda check: (check_label(check), check.get("link") or ""),
    )
    totals = Counter(check_label(check) for check in ordered)
    seen: Counter[str] = Counter()
    labelled: list[tuple[str, dict[str, Any]]] = []
    for check in ordered:
        base = check_label(check)
        seen[base] += 1
        label = f"{base} [{seen[base]}/{totals[base]}]" if totals[base] > 1 else base
        labelled.append((label, check))
    return labelled


def check_summary(checks: list[dict[str, Any]]) -> dict[str, Any]:
    buckets: dict[str, list[str]] = {
        "pass": [],
        "fail": [],
        "pending": [],
        "skipping": [],
        "cancel": [],
        "unknown": [],
    }
    for label, check in labelled_checks(checks):
        bucket = check.get("bucket") or "unknown"
        buckets.setdefault(bucket, []).append(label)
    for names in buckets.values():
        names.sort()
    terminal = bool(checks) and not buckets["pending"] and not buckets["unknown"]
    successful = terminal and not buckets["fail"] and not buckets["cancel"]
    return {
        "count": len(checks),
        "buckets": {key: value for key, value in buckets.items() if value},
        "terminal": terminal,
        "successful": successful,
    }


def fetch_checks(repo_slug: str, pr: str) -> list[dict[str, Any]]:
    return gh_json(
        repo_slug,
        "pr",
        "checks",
        pr,
        "--json",
        "name,bucket,state,link,workflow",
        allowed_codes=(0, 1, EXIT_PENDING),
    ) or []


def fetch_pr(repo_slug: str, pr: str) -> dict[str, Any]:
    return gh_json(
        repo_slug,
        "pr",
        "view",
        pr,
        "--json",
        "number,url,state,isDraft,baseRefName,headRefName,headRefOid,mergeStateStatus,closingIssuesReferences",
    )


def watch_ci(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    repo = resolve_repo(args.repo)
    repo_slug = resolve_github_repo(repo, args.github_repo)
    started = time.monotonic()
    initial_pr = fetch_pr(repo_slug, args.pr)
    initial_head = initial_pr["headRefOid"]
    transitions: list[dict[str, Any]] = []
    previous: dict[str, str] = {}

    while True:
        checks = fetch_checks(repo_slug, args.pr)
        current = {
            label: check.get("bucket", "unknown")
            for label, check in labelled_checks(checks)
        }
        changed = {
            name: bucket for name, bucket in current.items() if previous.get(name) != bucket
        }
        removed = sorted(set(previous) - set(current))
        if changed or removed:
            transitions.append(
                {
                    "elapsed_seconds": round(time.monotonic() - started, 1),
                    "changed": changed,
                    "removed": removed,
                }
            )
        previous = current
        summary = check_summary(checks)
        latest_pr = fetch_pr(repo_slug, args.pr)
        if latest_pr["headRefOid"] != initial_head:
            return {
                "schema": 1,
                "status": "stale",
                "pr": latest_pr,
                "initial_head": initial_head,
                "checks": summary,
                "transitions": transitions,
            }, EXIT_STALE
        if summary["terminal"]:
            status = "passed" if summary["successful"] else "failed"
            return {
                "schema": 1,
                "status": status,
                "pr": latest_pr,
                "initial_head": initial_head,
                "checks": summary,
                "transitions": transitions,
            }, 0 if summary["successful"] else EXIT_FAILED
        if time.monotonic() - started >= args.timeout:
            return {
                "schema": 1,
                "status": "pending",
                "pr": latest_pr,
                "initial_head": initial_head,
                "checks": summary,
                "transitions": transitions,
            }, EXIT_PENDING
        time.sleep(args.interval)


def evaluate_readiness(
    pr: dict[str, Any],
    checks: dict[str, Any],
    *,
    issue: int,
    base: str,
    expected_head: str | None,
    local_head: str,
    current_branch_name: str | None,
    status_matches: bool,
) -> dict[str, Any]:
    failures: list[str] = []
    if pr.get("state") != "OPEN":
        failures.append("pull request is not open")
    if pr.get("baseRefName") != base:
        failures.append(f"base is {pr.get('baseRefName')!r}, expected {base!r}")
    if issue not in reference_numbers(pr.get("closingIssuesReferences")):
        failures.append(f"pull request does not close issue #{issue}")
    required_head = expected_head or local_head
    if pr.get("headRefOid") != required_head:
        failures.append("pull request head does not match the expected local commit")
    if current_branch_name and pr.get("headRefName") != current_branch_name:
        failures.append("pull request head branch does not match the current branch")
    if not checks["count"]:
        failures.append("no CI checks are present")
    elif not checks["terminal"]:
        failures.append("CI checks are still pending")
    elif not checks["successful"]:
        failures.append("CI checks did not all pass or skip")
    if not status_matches:
        failures.append("worktree differs from the saved preflight baseline")
    return {
        "failures": failures,
        "ready_to_mark": not failures and bool(pr.get("isDraft")),
        "complete": not failures and not bool(pr.get("isDraft")),
    }


def readiness(args: argparse.Namespace) -> tuple[dict[str, Any], int]:
    repo = resolve_repo(args.repo)
    repo_slug = resolve_github_repo(repo, args.github_repo)
    pr = fetch_pr(repo_slug, args.pr)
    checks = check_summary(fetch_checks(repo_slug, args.pr))
    baseline = json.loads(Path(args.baseline).read_text(encoding="utf-8"))
    initial_status = baseline.get("status", [])
    final_status = status_lines(repo)
    initial_fingerprints = baseline.get("fingerprints", {})
    final_fingerprints = dirty_fingerprints(repo)
    fingerprint_changes = sorted(
        path
        for path in set(initial_fingerprints) | set(final_fingerprints)
        if initial_fingerprints.get(path) != final_fingerprints.get(path)
    )
    status_matches = initial_status == final_status and not fingerprint_changes
    local_head = git(repo, "rev-parse", "HEAD")
    evaluation = evaluate_readiness(
        pr,
        checks,
        issue=args.issue,
        base=args.base,
        expected_head=args.expected_head,
        local_head=local_head,
        current_branch_name=current_branch(repo),
        status_matches=status_matches,
    )
    result = {
        "schema": 1,
        "pr": pr,
        "checks": checks,
        "baseline": str(Path(args.baseline).resolve()),
        "worktree_matches_baseline": status_matches,
        "fingerprint_changes": fingerprint_changes,
        **evaluation,
    }
    if not status_matches:
        result["initial_status"] = initial_status
        result["final_status"] = final_status
    return result, 0 if evaluation["ready_to_mark"] or evaluation["complete"] else EXIT_FAILED


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Read-only, compact helpers for the ship-issue workflow."
    )
    parser.add_argument("--repo", default=".", help="Git repository path")
    parser.add_argument("--github-repo", help="GitHub OWNER/REPO override")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON")
    subparsers = parser.add_subparsers(dest="command", required=True)

    preflight_parser = subparsers.add_parser("preflight")
    preflight_parser.add_argument("--offline", action="store_true")
    preflight_parser.add_argument("--log-count", type=int, default=8)
    preflight_parser.add_argument("--save-baseline")
    preflight_parser.set_defaults(handler=preflight)

    inventory_parser = subparsers.add_parser("issue-inventory")
    inventory_parser.add_argument("--limit", type=int, default=100)
    inventory_parser.set_defaults(handler=issue_inventory)

    audit_parser = subparsers.add_parser("branch-audit")
    audit_parser.add_argument("--base", default="origin/main")
    audit_parser.add_argument("branches", nargs="*")
    audit_parser.set_defaults(handler=branch_audit)

    diff_parser = subparsers.add_parser("diff-summary")
    diff_parser.add_argument("--range")
    diff_parser.set_defaults(handler=diff_summary)

    body_parser = subparsers.add_parser("pr-body")
    body_parser.add_argument("--issue", type=int, required=True)
    body_parser.add_argument("--summary", action="append", required=True)
    body_parser.add_argument("--verification-report", required=True)
    body_parser.add_argument("--human-review", action="append", default=[])
    body_parser.add_argument("--body-file", required=True)
    body_parser.set_defaults(handler=pr_body)

    watch_parser = subparsers.add_parser("watch-ci")
    watch_parser.add_argument("pr")
    watch_parser.add_argument("--interval", type=float, default=10.0)
    watch_parser.add_argument("--timeout", type=float, default=50.0)
    watch_parser.set_defaults(handler=watch_ci)

    readiness_parser = subparsers.add_parser("readiness")
    readiness_parser.add_argument("pr")
    readiness_parser.add_argument("--issue", type=int, required=True)
    readiness_parser.add_argument("--base", default="main")
    readiness_parser.add_argument("--baseline", required=True)
    readiness_parser.add_argument("--expected-head")
    readiness_parser.set_defaults(handler=readiness)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        result, exit_code = args.handler(args)
        emit(result, pretty=args.pretty)
        return exit_code
    except (CommandError, ValueError, OSError, json.JSONDecodeError) as error:
        emit(
            {"schema": 1, "status": "error", "error": str(error)},
            pretty=args.pretty,
        )
        return EXIT_USAGE_OR_TOOL


if __name__ == "__main__":
    sys.exit(main())
