# Developer quick start

The quick-start keys build the configured local playtest directly from any screen, without the menu flow. F5 starts from the configured seed, F6 restarts with the current seed, and F7 restarts with the next seed. The diagnostics strip shows the active seed.

## Sub-features

- `qs-start` (F5) starts a Trial with the configured seed and Protocol.
- `qs-same` (F6) rebuilds the Trial with the same seed.
- `qs-next` (F7) increments the seed and rebuilds.

## How to get to it (user POV)

- Press `F5`, `F6` or `F7` while the game window has focus.

## Driving it with verify.sh

Preconditions:

- Main menu is showing with seed `20260812`.

- **Start.** Press F5. Run `key F5` then `wait_text "SEED 20260812" 5` and `expect "active_seed == 20260812 and TrialCoordinator.current_phase != TrialCoordinator.Phase.IDLE"`. The Trial is running from the configured seed.
- **Next seed.** Press F7. Run `key F7` then `wait_text "SEED 20260813" 5` and `expect "active_seed == 20260813"`.
- **Same seed.** Press F6. Run `key F6`, `wait 1.0`, `expect "active_seed == 20260813"` and `wait_text "SEED 20260813" 5`.
- **Proof.** `journeys/quick-start.steps` captures `01-f5-started`, `02-f7-next-seed` and `03-f6-same-seed` (PNG and JSON).

## Gotchas

- Quick start skips the presentation: the snapshot can report `screen` `experiment_brief` while `phase` is already `LABORATORY_ENTRY`. Assert `phase` and `active_seed`, not `screen`.
- F6 keeps the current seed, not the configured one. After F7, F6 stays on the incremented seed.
- Quick start is a developer path. Do not use it as proof of the player-facing menu flow (see [Local Trial](./local-trial.md)).
