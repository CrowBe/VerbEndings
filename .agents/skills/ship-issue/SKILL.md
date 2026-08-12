---
name: ship-issue
description: "Run the complete GitHub issue-to-review workflow for this repository: inspect and select an actionable issue, prepare a clean branch, implement and document the change, validate it with Godot 4.3 and project checks, create or update a draft pull request, monitor and repair CI, then mark the PR ready for review. Use when the user asks to take the next issue, complete an issue end to end, ship an issue, or prepare a PR for review rather than stopping at a local implementation or draft PR."
---

# Ship an issue

Own one issue from discovery through a review-ready PR. Continue through recoverable failures; do not stop at a local implementation, push, draft PR, or first CI run.

Use `scripts/ship_issue.py` for compact, deterministic Git and GitHub facts. Its subcommands are read-only except that `preflight --save-baseline` and `pr-body --body-file` write caller-selected temporary files. Keep branch changes, deletion, staging, commits, pushes, PR creation, and readiness transitions as explicit commands.

The helper emits compact JSON. Exit `0` means its invariant passed, `1` means a check or readiness invariant failed, `2` means configuration or tool access failed, `8` means CI remains pending, and `9` means the PR head changed during monitoring. Use `--pretty` only for human inspection.

## Completion contract

Finish only when all of these are true:

- One open, actionable issue has been implemented without unrelated scope.
- Current code and affected documentation agree with `AGENTS.md`, `CONTEXT.md`, and `docs/ARCHITECTURE.md`.
- `$verify-changes` reports `PASS` for the final local change using Godot 4.3.
- The branch is pushed and a PR links the issue with `Closes #<number>`.
- The final pushed commit is the commit whose required CI checks passed.
- The PR is no longer a draft and is ready for human review.
- The worktree contains no changes beyond those recorded in the initial baseline.

If access, an ambiguous product choice, or a genuine external failure prevents completion, report the exact blocker, evidence, completed work, and safest next action.

## 1. Establish repository and GitHub state

Read `AGENTS.md` first, then relevant product and architecture documents. Create a temporary baseline path with `mktemp`, then capture the repository and GitHub state before changing anything:

```bash
.agents/skills/ship-issue/scripts/ship_issue.py preflight --save-baseline <baseline-path>
```

Preserve every recorded modified or untracked user file. Never fold it into the issue commit. If it overlaps required work and cannot be isolated safely, report the collision.

Run only one implementation in a checkout at a time. Do not fan out parallel agents against the same working directory, index, or `HEAD`. Use separate worktrees for deliberate parallel work; avoid Git's shared stash as isolation.

If preflight exits `2` because GitHub is inaccessible inside the sandbox, retry that exact helper command through the environment's approval mechanism before asking the user to log in. Never print tokens or inspect credential files.

Synchronise remote state before choosing work:

```bash
git fetch --prune origin
```

Use escalation if network restrictions cause failure. Do not reset, force-push, or clean destructively.

## 2. Read and select an issue

Use a user-named issue. Otherwise obtain a compact inventory of open issues, blockers, matching PRs, and remote branches:

```bash
.agents/skills/ship-issue/scripts/ship_issue.py issue-inventory
```

Treat the output as an inventory, not an automated priority decision. Compare priority, milestone, dependencies, duplication, and scope, then read plausible candidates completely:

```bash
gh issue view <number> --comments
```

Prefer an explicitly prioritised, unblocked issue implementable as one coherent PR. If materially tied candidates would change product direction, ask; otherwise state a defensible selection. Resolve `#42` against the configured GitHub repository and confirm its exact title.

Write a short implementation contract covering required behaviour, out-of-scope work, affected current-state documentation, and verification evidence. Do not copy the issue backlog into documentation.

## 3. Prepare the branch safely

Use preflight to determine whether the current branch already has a PR or unique work. Never overwrite it because its name appears stale.

Audit cleanup candidates without modifying them:

```bash
.agents/skills/ship-issue/scripts/ship_issue.py branch-audit --base origin/main <candidate>...
```

Delete only a reviewed candidate reporting `safe_to_delete: true`, and use `git branch -d`, never `-D`. Do not delete remote branches unless explicitly requested.

Switch to current `main`, fast-forward it, and branch:

```bash
git switch main
git pull --ff-only origin main
git switch -c agent/issue-<number>-<short-slug>
```

Diagnose a non-fast-forward `main` rather than rebasing or resetting automatically. Verify any existing target branch before resuming it.

## 4. Implement the smallest complete solution

Inspect neighbouring code, tests, and terminology. Preserve `CONTEXT.md` invariants and use Australian/British spelling in prose.

Test changed behaviour through stable public seams established by the issue, specification, architecture, or neighbouring tests. When practical, add a failing focused test before each smallest passing slice. Update focused regressions and present-state documentation with the implementation; do not add changelogs, dated audits, migration narratives, ADRs, or planned-work lists.

Use the compact summary repeatedly, but inspect the complete diff whenever exercising judgement:

```bash
.agents/skills/ship-issue/scripts/ship_issue.py diff-summary
git diff
```

Keep generated Godot resources only when intentional. Do not add files recorded as pre-existing.

## 5. Verify the complete change

Invoke `$verify-changes` from `.agents/skills/verify-changes/SKILL.md` with the implementation contract, `origin/main` as comparison base, and the current worktree. Follow it completely.

Do not publish until its review-ready report says `PASS`. Fix in-scope failures and rerun affected checks. Save the final report at a temporary path for PR-body generation. If implementation changes afterwards, treat the report as stale and rerun `$verify-changes`.

## 6. Commit, self-review, and publish a draft PR

Inspect unstaged and staged changes. Stage only explicit intended paths; never use `git add -A` in a mixed worktree:

```bash
.agents/skills/ship-issue/scripts/ship_issue.py diff-summary
git diff
git diff --cached
```

Commit imperatively. Then review the committed branch against the fixed base:

```bash
.agents/skills/ship-issue/scripts/ship_issue.py diff-summary --range origin/main...HEAD
git diff origin/main...HEAD
```

Check accidental scope, missing tests, stale documentation, fragile ordering, lifecycle races, and error paths. Fix findings and rerun affected checks. Amend only before the first push; use follow-up commits afterwards.

Push without force, then generate the PR body. Repeat `--summary` and `--human-review` per item; omit human review when none remains:

```bash
git push -u origin HEAD
.agents/skills/ship-issue/scripts/ship_issue.py pr-body \
  --issue <number> \
  --summary "<implemented outcome>" \
  --verification-report <verification-report-path> \
  --human-review "<subjective review item>" \
  --body-file <temporary-body-path>
gh pr create --draft --base main --head <branch> --title "<title>" --body-file <temporary-body-path>
```

Reuse an existing PR instead of duplicating it. Verify the displayed diff contains only intended changes:

```bash
gh pr diff <pr-number>
gh pr view <pr-number> --json number,url,isDraft,baseRefName,headRefName,mergeStateStatus
```

Remove temporary body and report files after use.

## 7. Watch CI through success

Use the bounded, transition-only watcher until every check for one unchanged head reaches a successful or skipped terminal state:

```bash
.agents/skills/ship-issue/scripts/ship_issue.py watch-ci <pr-number>
```

Exit `8` means checks remain pending; invoke it again. Exit `9` means the head changed; restart for the new head. The helper does not exit early merely because one check fails while others remain pending.

For terminal failure, inspect logs with `gh run view <run-id> --log-failed`, reproduce locally where practical, fix, rerun `$verify-changes` as affected, commit, push, and restart monitoring. Distinguish code failures from cancellations, runner outages, and transient infrastructure failures. After success, check newly posted actionable review feedback.

## 8. Mark ready and hand off

Require the readiness helper to report `ready_to_mark: true`. It checks the closing issue, base and head, expected commit, CI, and worktree against the preflight baseline:

```bash
.agents/skills/ship-issue/scripts/ship_issue.py readiness <pr-number> \
  --issue <number> --baseline <baseline-path> --expected-head <commit>
```

Then perform the explicit transition and require `complete: true`:

```bash
gh pr ready <pr-number>
.agents/skills/ship-issue/scripts/ship_issue.py readiness <pr-number> \
  --issue <number> --baseline <baseline-path> --expected-head <commit>
```

Report issue and PR links, implementation, exact validation, CI, and human review notes. Do not claim the issue is closed before merge.
