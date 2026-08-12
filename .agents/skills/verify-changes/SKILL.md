---
name: verify-changes
description: "Validate repository changes and produce review-ready evidence. Use after implementation, before committing or publishing a pull request, when investigating whether a change is ready, or when another workflow such as ship-issue needs a single source of truth for Godot 4.3 checks, focused tests, runtime smoke testing, and conditional visual or control QA."
---

# Verify changes

Validate the complete user-facing effect of the current change, not only whether individual files parse. Discover the repository's current gates, run checks proportionate to the diff, and return one explicit `PASS` or `BLOCKED` report.

## Completion contract

Report `PASS` only when all of these are true:

- The validation scope covers the committed branch diff and relevant working-tree changes.
- Repository-mandated checks and every affected CI-equivalent gate pass with Godot 4.3.
- Focused tests exercise the changed behaviour at its stable public seams.
- Runtime, visual, camera, layout, or control changes have been exercised in the real renderer using the visual QA workflow.
- Command output has been checked for `ERROR`, `SCRIPT ERROR`, parse errors, and unexpected warnings even when the process exits successfully.
- Captures and measurements support the acceptance criteria; subjective judgements still requiring a person are labelled separately.
- Validation creates no unintended repository changes or artefacts.

If a required gate cannot run, report `BLOCKED`. Include the exact constraint and the safest next action; do not silently waive the gate.

## 1. Establish scope and preserve the worktree

Read `AGENTS.md` and inspect the repository before running tools:

```bash
git status --short --branch
git diff --name-status
git diff --check
```

Use the base supplied by the calling workflow. Otherwise, use the merge base with `origin/main` when available and inspect `git diff origin/main...HEAD` in addition to working-tree changes.

Record pre-existing modified and untracked files. Do not stage, rewrite, delete, import over, or include them in generated evidence. Put temporary probes, logs, screenshots, and reports in a directory created under `/tmp`.

Classify the change into every applicable category:

- documentation or project resources
- domain logic or data
- scenes, scripts, or runtime lifecycle
- networking or multiplayer
- rendered UI, spatial layout, camera, lighting, animation, or controls

Use the classification to add focused checks; it never removes a repository-mandated gate.

## 2. Discover the current validation contract

Read these files instead of copying a remembered command list into this skill:

- `AGENTS.md`
- `docs/VALIDATION.md`
- `.github/workflows/validation.yml`

Treat the documentation as the local developer contract and the workflow as the CI contract. Confirm the selected executable is Godot 4.3 before testing.

During implementation, run the narrowest affected checks first for quick feedback. For a final review-ready verification, run the repository baseline and every CI job affected by the change. Include import/parse checks, focused scene or wrapper suites, and timed runtime smoke checks whenever the discovered contract requires them.

Do not infer success from an exit code alone. Retain enough output to identify engine errors, script errors, parse failures, warnings, timeouts, crashes, or leaked nodes.

## 3. Exercise the changed behaviour

Map each acceptance criterion and changed public seam to at least one check. Prefer existing focused tests and harnesses. Add a focused regression test only when the caller has authorised implementation changes and the current suite does not observe the required behaviour.

For networking changes, exercise the relevant authority and peer configurations. A local-only test must initialise the repository's supported offline multiplayer peer before calling multiplayer identity APIs; do not dismiss `No multiplayer peer is assigned` as harmless output.

If the change affects anything a player sees, frames through, times, steers, or spatially navigates, read `references/visual-qa.md` completely and perform that workflow. Headless execution alone cannot pass a visually material acceptance criterion.

If visual QA is not applicable, record the concrete reason in the report, such as “documentation-only change” or “pure parser logic with no rendered consumer”.

## 4. Close the failure loop

When the calling task authorises changes, diagnose and fix validation failures, rerun the narrow failing check, then rerun every baseline gate the fix could affect. Do not weaken an assertion, remove coverage, or relabel unexpected output to manufacture a pass.

When the caller requested review or diagnosis only, do not edit the implementation. Report the failure with reproduction evidence.

After validation, compare `git status --short` with the initial snapshot. Remove only known temporary outputs created by this run. Never clean up pre-existing user files.

## 5. Return a verification report

Return a compact report with these fields:

```text
Verdict: PASS | BLOCKED
Scope: <base, head, working-tree scope, change classifications>
Acceptance evidence:
- <criterion>: <test, observation, capture, or measurement>
Commands:
- <exact command>: PASS | FAIL — <important output>
Visual QA: <PASS with evidence paths | BLOCKED with reason | NOT APPLICABLE with reason>
Unexpected output: <none | exact errors or warnings>
Worktree hygiene: <unchanged apart from pre-existing and intended files | details>
Human review: <remaining subjective questions, not automated claims>
```

When invoked by `$ship-issue`, return this report before the commit/publish phase. The shipping workflow may use it directly in the pull request description, but must rerun affected checks if later edits change the verified commit.
