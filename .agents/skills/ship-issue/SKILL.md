---
name: ship-issue
description: "Run the complete GitHub issue-to-review workflow for this repository: inspect and select an actionable issue, prepare a clean branch, implement and document the change, validate it with Godot 4.3 and project checks, create or update a draft pull request, monitor and repair CI, then mark the PR ready for review. Use when the user asks to take the next issue, complete an issue end to end, ship an issue, or prepare a PR for review rather than stopping at a local implementation or draft PR."
---

# Ship an issue

Own one issue from discovery through a review-ready PR. Continue autonomously through recoverable failures. Do not stop merely because the implementation, push, draft PR, or first CI run is complete.

## Completion contract

Finish only when all of these are true:

- One open, actionable issue has been implemented without unrelated scope.
- Current code and affected documentation agree with `AGENTS.md`, `CONTEXT.md`, and `docs/ARCHITECTURE.md`.
- Relevant local checks pass using Godot 4.3.
- The branch is pushed and a PR links the issue with `Closes #<number>`.
- The final pushed commit is the commit whose required CI checks passed.
- The PR is no longer a draft and is ready for human review.
- The worktree contains no new unintended files or edits.

If access, an ambiguous product choice, or a genuine external failure prevents completion, report the exact blocker, evidence, completed work, and safest next action.

## 1. Establish repository and GitHub state

Read `AGENTS.md` first, then the product and architecture documents relevant to the issue. Inspect the current branch, worktree, remotes, recent history, and worktrees before changing anything:

```bash
git status --short --branch
git remote -v
git worktree list
git branch -vv
git log --oneline --decorate -12
```

Preserve pre-existing user changes, including untracked files. Never fold them into the issue commit. If they overlap the required change and cannot be isolated safely, stop and explain the collision.

Run only one issue implementation in a checkout at a time. Do not fan out parallel agents or chats against the same working directory, index, or `HEAD`. Use separate worktrees for deliberate parallel work, and remember that Git's stash is shared across worktrees; avoid stashing as an isolation mechanism.

Test GitHub access with `gh auth status` and a small read such as `gh repo view`. A failed `gh auth status` inside the sandbox does not prove the host login is invalid: restricted access to credentials or `api.github.com` can produce misleading token and network errors. Retry the necessary `gh` command with the environment's escalation/approval mechanism before asking the user to log in. Never print tokens or inspect credential files.

Synchronise remote state before choosing work:

```bash
git fetch --prune origin
```

Use escalation if network restrictions cause the fetch to fail. Do not use `git reset --hard`, force-push, or destructive cleanup.

## 2. Read and select an issue

If the user names an issue, use it. Otherwise list all open issues with enough metadata to compare priority, labels, milestone, dependencies, and scope; then read the full body and comments of plausible candidates.

```bash
gh issue list --state open --limit 100 --json number,title,labels,milestone,assignees,updatedAt,url
gh issue view <number> --comments
```

Check open PRs and remote branches so work is not duplicated. Prefer an explicitly prioritised, unblocked issue whose acceptance criteria are implementable in one coherent PR. Respect dependency language in issue bodies and comments. If candidates remain materially tied and choosing one would change product direction, ask the user; otherwise make and state a defensible choice.

Resolve short references such as `#42` against the configured GitHub repository, then confirm the repository-qualified reference and exact issue title before implementation. Never guess from a numbered local checklist or a different tracker.

Translate the selected issue into a short implementation contract: required behaviour, out-of-scope work, affected current-state documentation, and verification evidence. Do not copy the issue backlog into repository documentation.

## 3. Clean up branches safely and branch from current main

First confirm whether the current branch already has a PR or unmerged commits. Never delete or overwrite it merely because its name looks stale.

Switch to `main`, fast-forward it, and create `agent/issue-<number>-<short-slug>`:

```bash
git switch main
git pull --ff-only origin main
git switch -c agent/issue-<number>-<short-slug>
```

If local `main` cannot fast-forward, diagnose instead of rebasing or resetting automatically. If the target branch already exists, verify its commits and PR association before deciding whether to resume it or choose a new name.

Clean stale local branches only after fetching and proving they are merged into `origin/main`, are not checked out by another worktree, and contain no unique work:

```bash
git branch --merged origin/main
git worktree list
git log origin/main..<candidate> --oneline
git branch -d <candidate>
```

Switch away from a merged branch before deleting it. Use `-d`, never `-D`. Do not delete remote branches unless the user explicitly requests it; `git fetch --prune` is sufficient for already-deleted remotes. Branch cleanup is hygiene, not a reason to touch active or uncertain work.

## 4. Implement the smallest complete solution

Inspect neighbouring code, tests, and current terminology before editing. Follow repository conventions and preserve domain invariants in `CONTEXT.md`. Use Australian/British spelling in prose.

Identify the stable public seams where the required behaviour can be observed. Prefer seams already established by the issue, specification, architecture, or neighbouring tests; do not invent an implementation-coupled test boundary mid-build. When practical, add a failing focused test at each seam before implementing its smallest passing slice, then rerun that focused test throughout the change.

Add or update focused regression tests with the implementation. Update current-state documentation in the same change when behaviour, architecture, validation commands, resources, or links change. Do not add changelogs, dated audits, migration narratives, ADRs, or planned-work lists.

Review the diff repeatedly:

```bash
git diff --check
git diff --stat
git diff
git status --short
```

Keep generated/imported Godot resources only when they are intentional. Do not add unrelated files observed at the start.

## 5. Validate locally

Run the narrowest relevant tests while iterating, then run the repository-required gates. Always run:

```bash
python3 tools/validate_project.py
```

Use Godot 4.3 for import, parse, runtime, and test checks. Read `docs/VALIDATION.md` and `.github/workflows/validation.yml`; mirror every CI step affected by the change. On this repository, use the available 4.3 binary (`godot4.3` locally or `godot` when it is the pinned 4.3 executable), and scan output for `ERROR`, `SCRIPT ERROR`, parse errors, and unexpected warnings even when the exit code is zero.

At minimum, perform the native import/parse check, the relevant focused scene tests, and any wrapper tests touched by the change. Run the timed runtime smoke check when runtime behaviour or shared project resources change. For visual or control changes, perform graphical inspection or clearly identify the human-only verification still needed; headless success does not establish visual quality.

Fix failures rather than weakening assertions. Record exact commands and outcomes for the PR body.

## 6. Commit, self-review, and publish a draft PR

Before committing, inspect both unstaged and staged changes. Stage only explicit intended paths; never use `git add -A` in a mixed worktree:

```bash
git diff --check
git diff
git diff --cached
git status --short
```

Commit with an imperative message. Then review the committed branch against the fixed base; doing this before the commit would omit working-tree changes from the triple-dot diff:

```bash
git diff --check origin/main...HEAD
git diff --stat origin/main...HEAD
git diff origin/main...HEAD
git status --short
```

Check for accidental scope, missing tests, stale documentation, fragile ordering, lifecycle races, and error paths. Fix findings, rerun affected checks, and update the local commit before its first push. After a branch has been pushed, use follow-up commits rather than rewriting published history.

Push without force:

```bash
git push -u origin HEAD
```

Create a draft PR. Include a concise summary, validation commands and results, and `Closes #<number>` in the body. Verify the base is `main`, the head is the issue branch, and the displayed diff contains only intended changes.

```bash
gh pr create --draft --base main --head <branch> --title "<title>" --body-file <body-file>
gh pr diff <pr-number>
gh pr view <pr-number> --json number,url,isDraft,baseRefName,headRefName,mergeStateStatus
```

Use a temporary file outside the repository for `--body-file`, and remove it afterwards. If a PR already exists for the branch, update and reuse it instead of creating a duplicate.

## 7. Watch CI through success

Do not mark the PR ready immediately after pushing. Watch checks for the latest commit until all required checks reach a terminal successful or neutral/skipped state:

```bash
gh pr checks <pr-number> --watch --interval 10
gh pr view <pr-number> --json headRefOid,statusCheckRollup,mergeStateStatus,isDraft,url
```

Do not use an early failure mode that exits while other checks remain pending. If CI fails, inspect the failing run and logs (`gh run view <run-id> --log-failed`), reproduce locally where practical, implement the fix, rerun relevant local checks, commit, push, and watch the new head from the beginning. Distinguish code failures from cancelled jobs, runner outages, and transient infrastructure failures; rerun only when evidence supports a transient failure.

After CI reports success, confirm `headRefOid` still matches the commit that was tested and no new check is queued. If the head changed, watch again. Also check for newly posted actionable review feedback and address it before readiness when it is already present.

## 8. Mark ready and hand off

Only after the completion contract is satisfied, run:

```bash
gh pr ready <pr-number>
gh pr view <pr-number> --json url,isDraft,headRefOid,statusCheckRollup,mergeStateStatus
git status --short --branch
```

Confirm `isDraft` is false and required checks still pass. Report the issue and PR links, implementation summary, exact validation performed, CI result, and any human-only review note. Do not claim the issue is closed before the PR merges.
