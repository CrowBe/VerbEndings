# Session diagnostics

The bottom-right diagnostics strip shows the build identifier and Trial seed at all times. Pressing F8, or choosing the strip, opens a privacy-safe JSON session summary that the player can copy. The same summary is stored as `latest_session_summary.json` in the Godot user-data folder.

## Sub-features

- `diag-strip` shows `BUILD <id>  •  SEED <seed>  •  F8 DIAGNOSTICS`.
- `diag-open` opens the `SESSION DIAGNOSTICS` panel with the summary JSON.
- `diag-copy` copies the summary and reports the stored file path.
- `diag-close` closes the panel.
- `diag-file` persists `user://latest_session_summary.json`.

## How to get to it (user POV)

- Press `F8` on any screen.
- Choose the diagnostics strip button at the bottom right.
- Choose `COPY SUMMARY`, then `CLOSE`, inside the panel.

## Driving it with verify.sh

Preconditions:

- Main menu is showing with seed `20260812`.

- **Strip.** Read the strip. Run `wait_text "BUILD mvp-playtest.1" 5`. The strip shows the build and seed.
- **Open.** Press F8. Run `key F8` then `wait_text "SESSION DIAGNOSTICS" 5`. The panel lists the summary, including `'"trial_seed": 20260812'`.
- **Copy.** Choose `COPY SUMMARY`. Run `click "COPY SUMMARY"` then `wait_text "Summary copied." 5`. The status names a path under the run's `data/` directory, which proves `user://` isolation.
- **Close.** Choose `CLOSE`. Run `click "CLOSE"` then `expect_absent "SESSION DIAGNOSTICS"`.
- **File.** Run `copy_user latest_session_summary.json`. The evidence contains the stored JSON.
- **Proof.** `journeys/diagnostics.steps` captures `01-main-menu.png`, `02-diagnostics-open.png`/`.json`, `03-diagnostics-closed.png` and `latest_session_summary.json`.

## Gotchas

- `COPY SUMMARY` writes to the desktop clipboard. Expect it to replace whatever the user had copied.
- On the main menu the summary's `final_result.status` is `incomplete` and `protocol_order` is empty. Assert those fields only after a Trial.
- The strip is a `Button` whose text changes with the seed. Match it with `wait_text`, not `click`.
