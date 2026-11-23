# Host and join

One player chooses `HOST SESSION` and the other enters the host's address and port, then chooses `JOIN SESSION`. Each claims a unique Verb, the host chooses `START TRIAL`, and both play the same server-authoritative Trial: the slowest claimer chooses a Partner in the Pair Draft, and both peers see the same Verb Chains, Brief, Stability, scores and result.

## Sub-features

- `hj-host` opens an ENet session on the chosen port (default `28714`) and enrols the host as Subject 1.
- `hj-join` connects to the host and receives the roster.
- `hj-claim` lets the client claim a Verb the host has not taken.
- `hj-start` shows `START TRIAL` once every connected Subject has a Verb.
- `hj-draft` lets the chooser on either peer pick a `SUBJECT <id> — <VERB>` Partner, and both see the result.
- `hj-brief` shows the same Experiment Brief, including Verb Chains, on both peers.

## How to get to it (user POV)

- Host: choose `HOST SESSION` on the main menu (optionally set `SessionPort` first).
- Client: set `HostAddress` (default `127.0.0.1`) and `SessionPort`, then choose `JOIN SESSION`.
- Host: choose `START TRIAL` on the `VERB SELECTION COMPLETE` screen.

## Driving it with verify.sh

Preconditions:

- Doctor reports UDP `28714` free, or both journeys first `click_node SessionPort`, `key ctrl+a`, `type "<port>"`, `key Enter`.
- Host journey started about 2 s before the client journey (see `../SKILL.md`, Drive).

- **Host.** Choose `HOST SESSION` and claim `BURN`. Run `click "HOST SESSION"`, `wait_screen verb_selection 10`, `click "BURN"`.
- **Join.** Choose `JOIN SESSION`. Client runs `click "JOIN SESSION"` then `wait_text "claim one unique Verb" 20`, `wait 2.0`.
- **Claim.** The client claims `SHIELD`. Client runs `click "SHIELD"`. The host roster then lists `— SHIELD` (`wait_text "— SHIELD" 60`).
- **Start.** The host chooses `START TRIAL`. Run `click "START TRIAL"`, then on both peers `wait_screen pair_draft 30`. The host reads `Subject <client id> chooses a Partner.`
- **Draft.** The client chooses the host. Client runs `wait_text "SUBJECT 1 — BURN" 15` then `click "SUBJECT 1 — BURN"`.
- **Brief.** Both peers run `wait_screen experiment_brief`, `expect_text "+ Subject 1"` and `expect "VerbChainManager.get_partner_id(1) > 1"`. The chooser is listed first, so the line reads `Subject <client id> + Subject 1`.
- **Proof.** Compare `03-host-experiment-brief.json` with `03-client-experiment-brief.json`. The Verb Chains lines must match. `02-client-pair-draft.png` shows the client's `SUBJECT 1 — BURN` choice.

## Gotchas

- Currently fails at **Draft**. The client stays on `The Semantic Engine is assigning the Dispensing Line.` and never gets Partner buttons, while the host waits on the client. The host eventually proceeds with Self-Chains, so **Brief** fails on the host too. The cause: `LobbyManager._start_draft` emits `draft_started`, which publishes a full snapshot, before `_advance_draft_turn` assigns `current_chooser_id`, and `NetworkSession` does not publish on `draft_turn_started`. Clients therefore never receive the first chooser. Keep the journey strict and record the failure.
- Each early authoritative snapshot rebuilds the client's Verb grid, and a click that lands during a rebuild is lost. The client waits 2 s after the grid appears before claiming.
- Two windows open, and a tiling compositor resizes the first when the second appears. Coordinates are recomputed per click, so this is harmless, but screenshot sizes differ between peers.
- `START TRIAL` appears as soon as every *connected* Subject has a Verb, including when the host is alone. Wait for the client's claim before choosing it.
- When the host process exits, the client falls back to the main menu (`server_disconnected`). A client failure after the host's last step is not a client defect. Keep the host up (`wait 8.0`) until the client has captured its proof.
- `tests/run_network_session_test.py` passes because it drives peers through domain calls with automatic Pair Drafts. It does not cover this journey.
