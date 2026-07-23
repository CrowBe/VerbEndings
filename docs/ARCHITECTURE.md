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
| `ScoreManager` | Stores per-Player points, awards placement and bonus points, exposes rankings, and provides lowest-score-first draft ordering. |
| `RoundManager` | Shuffles PVP, PVE, and Puzzle classifications without replacement, tracks the current Round, and gates Player-versus-Player Impacts. |
| `LobbyManager` | Tracks the roster, unique Verb claims, timed Verb Selection, Pair Draft order, and shared insertion-platform occupancy. |
| `SuddenDeathManager` | Calculates pair-summed end-state scores, starts its solo elimination state, applies Verb-specific multipliers, and declares the final survivor. |

These are stateful in-process services. Comments identify intended RPC and replication boundaries, but the methods and signals currently execute locally.

## Actors And Interaction

`Player.gd` is a third-person `CharacterBody3D` controller with camera-relative movement, jumping, a basic fist Impact, a tether penalty, nine Verbs, timed buffs, and procedural tween animation. Its implemented resource model uses `health`, `damage`, `died`, and `revive`; Verb use is cooldown-only. The scene is directly coupled to its primitive visual children and camera rig.

`SwarmMonster.gd` is a pursuing `CharacterBody3D`. It finds the nearest living Player, attacks in range, scales over time, can evolve, and can assume the Verb of a defeated Player. PVE code addresses these actors through the `monsters` group.

The implemented input map is WASD movement, Space jump, left mouse basic hit, right mouse Verb use, and Escape mouse capture.

## Experiments

`PuzzleRound` scatters five physics puzzle units and ranks Players by completed-unit contributions. The available units are:

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

- canonical Stability, Expression Cost, and Impact-only Destabilisation are not implemented;
- the Pair Draft supports only Round One and Round Two entry points;
- the insertion platform is not the canonical Drop sequence;
- Trial resolution uses pair totals and a non-canonical solo state;
- Residual and Collapse terminology and behaviour are not implemented;
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
