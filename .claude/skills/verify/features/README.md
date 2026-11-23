# VerbEndings verification map

This directory is the maintained source for verifying the player-facing behaviour of VerbEndings. Read this index before driving the game, then use the matching feature file as the recipe. The step language and wrapper are documented in `../SKILL.md`.

## Baseline preconditions

- `scripts/verify.sh doctor` passes: Godot 4.3-stable, runtime LFS objects, import cache, reachable display, no live verification instance.
- Every run starts from the main menu with an empty per-run `user://` (`XDG_DATA_HOME=/tmp/verbendings-verify/<run-id>/data`).
- `resources/local_playtest.tres` is unmodified: seed `20260812`, one local Subject, quick-start Protocol `ENVIRONMENT`. A journey that needs another roster states it in its preconditions.
- Never drive an instance that this run did not start.

## Driving conventions

- Start every journey with `wait_screen main_menu 15`.
- Prefer exact button texts and node names from `TrialPresentation.gd` over coordinates.
- Use `wait_screen`/`wait_phase`/`wait_text` with a timeout instead of fixed sleeps. Use `wait` only to let a replicated or animated state settle, and say why in a comment.
- Use `inspect`/`expect` only to observe state the screen cannot show, never to change it.
- Run one journey per process. For host/join, run one process per peer.

## Proof and skip reporting

- Capture the action and the resulting state, not only the final screen.
- UI proof is a `snapshot` (JSON with visible controls) plus a `shot` (PNG) of the same moment.
- Domain proof is an `expect` or `inspect` naming the exact expression and value.
- Report the journey file, run id and evidence directory with every claim.
- Report an unreachable path with the failing step and its `failure.png`/`failure.json`. Do not report a skipped entry point as verified through a different path.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph describing the player-visible behaviour, then exactly four H2 sections in this order: `Sub-features`, `How to get to it (user POV)`, `Driving it with verify.sh`, `Gotchas`. Keep implementation detail out of the map except the stable handles and observation expressions a journey needs.

## Features

| Feature | Journey | Status |
| --- | --- | --- |
| [Session diagnostics](./diagnostics.md) | `journeys/diagnostics.steps` | Passes |
| [Local Trial](./local-trial.md) | `journeys/local-trial-entry.steps` | Passes through the Experiment HUD; Trial completion has no journey yet |
| [Developer quick start](./quick-start.md) | `journeys/quick-start.steps` | Passes |
| [Host and join](./host-join.md) | `journeys/host-join-host.steps` + `journeys/host-join-client.steps` | Passes through the shared Experiment Brief |
