# Architecture

[`CONTEXT.md`](../CONTEXT.md) defines canonical product rules and domain language. This document describes the software currently present in the repository. Names in backticks are literal code identifiers, including identifiers that do not yet match the domain language.

## Runtime

VerbEndings is a Godot 4.3 project using Forward Plus rendering. `scenes/core/Game.tscn` is the configured main scene. Its `Game` script owns three child roots:

- `World`, the runtime world container;
- `Players`, the actor container; and
- `Round`, the active Experiment scene container.

On startup, `Game.gd` loads a requested Puzzle or PVE Round and creates one local `Player`. PVP is recognised by the Round manager but has no scene in `Game.ROUND_SCENES`. There is no menu, lobby scene, UI, network peer, `MultiplayerSpawner`, or `MultiplayerSynchronizer` in the runtime.

## Autoload Services

| Service | Current responsibility |
| --- | --- |
| `VerbChainManager` | Registers Players and Verbs, forms and dissolves two-Subject or Self-Chains, and calculates synergy and versatility values. |
| `ScoreManager` | Stores Subject-owned Round Scores and cumulative Trial Scores, exposes Trial Ranking, and provides lowest-score-first draft ordering. |
| `RoundManager` | Shuffles PVP, PVE, and Puzzle classifications without replacement, tracks the current Round, and gates Player-versus-Player Impacts. |
| `LobbyManager` | Tracks the roster, unique Verb claims, timed Verb Selection, Pair Draft order, and shared insertion-platform occupancy. |
| `CollapseManager` | Resolves individual First Place, starts the Collapse for a tie, applies universal Overdrive, and declares the final survivor. |

These are stateful in-process services. Comments identify intended RPC and replication boundaries, but the methods and signals currently execute locally.

## Actors And Interaction

`Player.gd` is a third-person `CharacterBody3D` controller with camera-relative movement, jumping, a basic fist Impact, a tether penalty, nine Verbs, timed buffs, and procedural tween animation. Every Subject has baseline Stability, configurable per-Verb Expression Costs, a 1-Stability self-spend floor, Critical Stability hooks, external-Impact Destabilisation, and normal-Experiment Restabilisation. Subjects and Residuals shed configurable Material on Impact and Destabilisation. A live Subject below baseline absorbs Material on contact to Restabilise without exceeding baseline. The scene is directly coupled to its primitive visual children and camera rig.

`Residual.gd` is a pursuing `CharacterBody3D`. It finds the nearest stable Subject, attacks in range, scales over time, can evolve, and can assume the Verb of a Destabilised Subject. PVE code addresses these actors through the `residuals` group.

The implemented input map is WASD movement, Space jump, left mouse basic hit, right mouse Verb use, and Escape mouse capture.

## Experiments

`PuzzleRound` scatters five physics puzzle units, dispenses Material through a visible Semantic Engine apparatus, and ranks Players by completed-unit contributions. Dispensing stops while the Semantic Engine is offline during the Collapse. The available units are:

- Momentum Turbine;
- Counterweight Plate;
- Wrecking Pendulum;
- Gravity Funnel; and
- Domino Tower.

`PuzzleUnit` provides shared contribution tracking, Verb power modifiers, completion signals, and helpers for procedural physics bodies.

`PVERound` spawns increasingly frequent and strong hostile waves around living Players. It scores kills and survival ticks, evolves hostiles after 90 seconds, and transfers a Destabilised Player's Verb to the responsible hostile.

Both Round controllers emit an ordered list when asked to end. Neither controls the complete three-Round Trial lifecycle from the main scene.

## Scene And State Boundaries

| Layer | Owns | Does not own |
| --- | --- | --- |
| `Game` | Scene composition, active Round instance, local Player instance | Scoring formulas, Pair rules, actor behaviour |
| Autoload services | Cross-scene roster, chain, score, Round, and final-resolution state | Render geometry and per-frame actor simulation |
| Round controllers | Experiment-local spawning, scoring inputs, ordering, cleanup | Verb Selection and persistent Trial presentation |
| Actors | Input, movement, Impacts, Verb effects, actor-local state | Trial ranking and Round selection |
| Puzzle units | One physics interaction and its contributors | Global score and Trial state |

## Current Capability Boundary

The repository provides a locally runnable gameplay greybox and domain service prototypes. It does not currently provide an end-to-end canonical Trial. In particular:

- Material dispensing is currently wired only into the Puzzle Experiment;
- the Pair Draft has entry points for all three Rounds;
- the insertion platform is not the canonical Drop sequence;
- Trial resolution uses individual Trial Scores and starts the Collapse for tied First Place;
- the full Compound-wide Collapse environment and Residual pacing are not implemented;
- PVP has no Experiment scene;
- the Compound, Assignment Deck, Laboratories, Dispensing Line, Recall, Result Announcement, and Thematic Moments are design contracts only; and
- multiplayer transport, replication, deterministic scenarios, UI, audio, production art, and automated gameplay tests are absent.

GitHub issues own implementation work. This document records capability boundaries only.

## Dependencies And Extension Rules

- Keep the main scene as a composition root; domain calculations belong in services or focused domain objects.
- Keep Round-local nodes and cleanup inside Round scenes.
- Keep server-authoritative decisions separate from presentation when networking is introduced.
- Do not treat RPC comments as implemented networking guarantees.
- Preserve the integer ordering of `Enums.VerbType`; append new values because the values are intended for serialisation.
- Keep gameplay collision in Godot scenes and presentation assets replaceable behind stable scene boundaries.
