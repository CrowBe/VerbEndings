# Local Trial

`LOCAL TRIAL` runs the configured roster on one computer. The player claims a unique Verb, sees the Pair Draft result and the Experiment Brief, enters the Laboratory with an independent Release and steerable Drop, then plays the timed Experiment with the HUD. Recall, the Result Announcement and two more Rounds follow, ending with a Trial Winner or the Collapse.

## Sub-features

- `lt-verb` claims one unique Verb within the 30-second selection window.
- `lt-draft` forms Pairs, or a Self-Chain for the odd Subject.
- `lt-brief` shows the Protocol name, Verb Chains, Objective, conditions and hazards.
- `lt-entry` releases the Subject with Space and steers the Drop with WASD; automatic Release follows at 3.0 s.
- `lt-hud` shows Round/phase, Stability, Verb Expression cooldown, Round Score, Objective and time remaining.
- `lt-result` shows the Result Announcement and `CONTINUE` (no journey yet).
- `lt-complete` shows `TRIAL COMPLETE` and `MAIN MENU` after Round Three (no journey yet).

## How to get to it (user POV)

- Choose `LOCAL TRIAL` on the main menu.
- Choose a Verb button in the `VerbChoices` grid.
- Choose `ENTER LABORATORY` on the Experiment Brief.
- Press `Space` during Laboratory Entry and hold `W`/`A`/`S`/`D` to steer.

## Driving it with verify.sh

Preconditions:

- Default `local_playtest.tres` (one local Subject, seed `20260812`).

- **Start.** Choose `LOCAL TRIAL`. Run `click "LOCAL TRIAL"` then `wait_screen verb_selection 10`. The heading reads `Subject 1 — claim one unique Verb`.
- **Claim.** Choose `BURN`. Run `click "BURN"`. With one Subject the Pair Draft resolves immediately to a Self-Chain.
- **Brief.** Run `wait_screen experiment_brief 30` then `expect_text "Subject 1 forms a Self-Chain"`. The Brief shows `ADAPTIVE CONTAINMENT` and its Objective.
- **Enter.** Choose `ENTER LABORATORY`. Run `click "ENTER LABORATORY"` then `wait_phase LABORATORY_ENTRY 10` and `wait_text "SPACE TO RELEASE" 5`.
- **Release.** Press Space. Run `key Space` then `expect "laboratory_transit._released.get(local_player.get_multiplayer_authority(), false) and laboratory_transit._elapsed < 3.0"`. The Release came from the key, not the automatic fallback.
- **Steer.** Hold W. Run `hold W 1.0` then `shot 04-drop`.
- **HUD.** Run `wait_screen hud 60` then `wait_text "STABILITY" 5`. The HUD reads `ROUND 1 • EXPERIMENT`, `STABILITY 100 / 100`, `VERB EXPRESSION READY`, `ROUND SCORE 0` and `TIME REMAINING 02:59`.
- **Proof.** `journeys/local-trial-entry.steps` captures `01-verb-selection`, `03-experiment-brief`, `04-laboratory-entry`, `04-release.json`, `04-drop` and `05-experiment-hud`.

## Gotchas

- A one-Subject roster never shows the `pair_draft` screen. `wait_phase PAIR_DRAFT` times out; wait for `experiment_brief` instead.
- During the Experiment the game captures the mouse. On the user's desktop this locks their pointer while the window has focus. Journeys end with `key Escape`, the player's own release.
- The `LABORATORY ENTRY` banner stays on its 4-second timer and shows through behind the HUD for its remaining time.
- `presentation_snapshot().hud_text` includes the hidden `◆ CRITICAL STABILITY ◆` label text. Use `critical_cue_visible` for the cue's state.
- Each Experiment lasts its Protocol's `duration_seconds` (180 s by default), so a full three-Round journey takes more than 10 minutes. Give `run` a matching `--timeout`.
