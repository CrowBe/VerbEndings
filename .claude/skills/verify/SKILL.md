---
name: verify
description: "Drive the real VerbEndings Godot 4.3 game the way a player does — main menu, local Trial, Laboratory Entry, HUD, F5–F8 keys, ENet host/join — and capture screenshots, UI snapshots and state evidence. Use to prove a gameplay, UI, lifecycle or multiplayer change works in the running game, when asked to verify/drive/screenshot the game, or when a playbook calls for the driver skill. Complements verify-changes, which runs the static and headless test gates."
---

# Verify VerbEndings by driving the game

VerbEndings is a Godot 4.3 desktop game. The player surface is one window: a main menu and lifecycle panels (`TrialPresentation`), then a 3D Compound with an in-Experiment HUD. There is no server to keep alive. Each verification run is one Godot process that boots the real main scene (`res://scenes/core/Game.tscn`) with all autoloads, executes a step file through `scripts/drive.gd`, and exits.

`drive.gd` injects real input with `Input.parse_input_event`. Clicks resolve through Godot's GUI hit-testing at the control's on-screen position, and keys go through the project InputMap. Screenshots come from the game's own viewport, never the user's desktop.

Paths below are relative to this skill directory (`.claude/skills/verify/`). The repository root is two levels up.

## Launch

Prerequisites (one-time per checkout, all checked by Doctor):

- Godot 4.3-stable on `PATH` as `godot4.3`, or set `GODOT=/path/to/godot`.
- Runtime Git LFS objects pulled: `git lfs pull --exclude="docs/art/**,assets/source/**"` from the repo root. Without them the GLBs are pointer files and import fails with `Expected 'true','false' or 'null', got 'version'`.
- Import cache built: `scripts/verify.sh prepare`. This runs the headless editor import, fails on any `ERROR`/`SCRIPT ERROR`/`Parse Error`, and deletes the untracked `.import` sidecars that the import creates under `docs/art/` folders without a `.gdignore`.

Run one journey:

```bash
scripts/verify.sh run journeys/local-trial-entry.steps            # run id defaults to <journey>-<timestamp>
scripts/verify.sh run journeys/diagnostics.steps --run-id my-check --timeout 60
```

The wrapper picks Wayland (falls back to discovering `/run/user/$UID/wayland-*`) or X11, sets `XDG_DATA_HOME=/tmp/verbendings-verify/<run-id>/data` so `user://` (including `latest_session_summary.json`) is private to the run, and launches:

```bash
godot4.3 --display-driver wayland --path <repo> --script scripts/drive.gd -- --steps <file> --out <evidence-dir>
```

Ready means the main menu is usable. Every journey's first step is `wait_screen main_menu 15`. `run` exits 0 only when every step passes **and** the engine log has no `ERROR:`, `SCRIPT ERROR` or `Parse Error`. It always tears down its own process and data dir.

A window opens on the user's current workspace and the compositor may tile it. Evidence records the real window size. Headless Godot uses a dummy renderer: `--headless` runs are valid for state assertions only, never for visual claims.

## Doctor

```bash
scripts/verify.sh doctor
```

Read-only. It checks Godot is 4.3-stable, git-lfs works, runtime LFS files are real, the import cache exists, a display is reachable, and no earlier verification instance is still running. It also notes when UDP 28714 (the default session port) is taken. Run it first and whenever a run behaves strangely. Fix every `FAIL` line with the hint it prints before driving.

## Drive

Write a step file: one step per line, `#` comments, and arguments quoted with `"..."` or `'...'` (single quotes let you match JSON such as `'"trial_seed": 20260812'`). Checked-in journeys live in `journeys/`. Put ad hoc ones in a scratch directory.

| Step | Effect |
| --- | --- |
| `wait_screen <screen> [s]` | Wait for `TrialPresentation.current_screen`: `main_menu`, `verb_selection`, `pair_draft`, `experiment_brief`, `hud`, `result_announcement`, `trial_complete`. |
| `wait_phase <PHASE> [s]` | Wait for the `TrialCoordinator.Phase` key: `IDLE`, `VERB_SELECTION`, `PAIR_DRAFT`, `EXPERIMENT_BRIEF`, `LABORATORY_ENTRY`, `EXPERIMENT`, `RECALL`, `RESULT_ANNOUNCEMENT`, `COLLAPSE`, `COMPLETE`. |
| `wait_text "<text>" [s]` | Wait until any visible Label/Button/LineEdit/TextEdit contains the text (default 10 s). |
| `expect_text "<text>"` / `expect_absent "<text>"` | Assert visible text now. |
| `click "<button text>"` | Click the visible, enabled button whose text matches exactly. On failure it logs the visible buttons. |
| `click_node <NodeName>` | Click a visible control by node name, such as `HostAddress` or `SessionPort`. |
| `key <Key>` | Press and release a key: `F5`–`F8`, `Space`, `Escape`, `Enter`, `ctrl+a`. |
| `hold <Key> <s>` | Hold a key, such as `hold W 1.0` to steer. |
| `type "<text>"` | Type characters into the focused control. |
| `mouse left\|right` | Click at the window centre: left is a basic Impact, right Expresses the Verb. |
| `wait <s>` | Sleep in game time. |
| `shot <name>` | Save `<name>.png` from the game viewport. |
| `snapshot <name>` | Save `<name>.json`: `presentation_snapshot()`, phase, round, window size and every visible control's type, name, text and rect. |
| `inspect <name> "<expr>"` | Save the value of a Godot `Expression` to `<name>.json`. |
| `expect "<expr>"` | Assert an `Expression` is `true`. |
| `copy_user <file>` | Copy `user://<file>` into the evidence. |
| `quit` | End the run. |

`inspect` and `expect` evaluate against the Game root (`active_seed`, `local_player`, `laboratory_transit`, `get_tree()`) with every autoload bound by name (`TrialCoordinator`, `LobbyManager`, `NetworkSession`, `VerbChainManager`, `ScoreManager`, `RoundManager`, …). `Engine` and `Time` are not visible. Use them for observation only: never call mutating methods, because that bypasses the user path the proof claims.

Stable handles: button texts are uppercase literals from `scripts/presentation/TrialPresentation.gd` (`LOCAL TRIAL`, `HOST SESSION`, `JOIN SESSION`, `START TRIAL`, `ENTER LABORATORY`, `CONTINUE`, `MAIN MENU`, `COPY SUMMARY`, `CLOSE`, Verb names such as `BURN`/`SHIELD`, Partner buttons `SUBJECT <id> — <VERB>`). Named nodes: `HostAddress`, `SessionPort`, `DiagnosticsStrip`, `VerbChoices`, `PartnerChoices`, `ExperimentHUD`. When a label changes in that file, update the journeys and feature files.

For two peers, start the host journey in the background, wait about 2 s, then run the client journey. Each instance gets its own run id and data dir:

```bash
scripts/verify.sh run journeys/host-join-host.steps --run-id hj-host > /tmp/hj-host.out 2>&1 &
sleep 2; scripts/verify.sh run journeys/host-join-client.steps --run-id hj-client; wait; tail -1 /tmp/hj-host.out
```

## Evidence

Each run writes to `/tmp/verbendings-verify/<run-id>/evidence/` (override the root with `VERIFY_ARTIFACTS`): the PNGs and JSON named by the journey, `steps.log` (every step, assertion result and path), and `godot.log` (full engine output). On a failing step the driver also writes `failure.png` and `failure.json`. Open the PNGs with the image reader before claiming a visual result.

Proof standards:

- Drive the real player path: buttons, keys and the menu flow. Use `F5`–`F7` only when the claim is about the developer quick start.
- Capture the action and the resulting state: a `shot`/`snapshot` before and after each transition the claim depends on, not only the final screen.
- When an automatic fallback could produce the same end state, assert the user action caused it. Laboratory Entry auto-releases every Subject at 3.0 s, so `local-trial-entry` asserts the Release happened while `laboratory_transit._elapsed < 3.0`. Run a negative control (the same journey without the action) once when adding such an assertion, and confirm it fails.
- Check side effects alongside the screen: `copy_user latest_session_summary.json` for diagnostics, and `inspect` for domain state.
- For multiplayer, compare host and client snapshots of the same moment. Agreement on one side proves nothing about the other.
- Headless runs, `tests/*.tscn` suites and `verify-changes` gates do not prove what a player sees.

## Cleanup

`run` cleans up after itself. If a run was interrupted:

```bash
scripts/verify.sh cleanup <run-id>
```

This stops only the Godot PID recorded in that run's `godot.pid` (never kill by process name: the user may have the editor or a playtest open), deletes `data/`, and keeps `evidence/`. Delete old evidence directories yourself when they are no longer needed. After `prepare`, `git status --short` must match its state before the run.

## Helpers

- `scripts/verify.sh` (`doctor`, `prepare`, `run`, `cleanup`) is the only entry point you need. Run it with no arguments for usage.
- `scripts/drive.gd` is the step interpreter. Add a step verb there, document it in the table above, and keep it input-driven.
- `journeys/*.steps` are the maintained journeys, one or more per feature in `features/`.

Read `features/README.md` before driving, then the feature file for the behaviour you are proving.
