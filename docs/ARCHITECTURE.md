# Architecture

[`CONTEXT.md`](../CONTEXT.md) defines canonical product rules and domain language. This document describes the software currently present in the repository. Names in backticks are literal code identifiers, including identifiers that do not yet match the domain language.

## Runtime

VerbEndings is a Godot 4.3 project using Forward Plus rendering. `scenes/core/Game.tscn` is the configured main scene. Its `Game` script owns the `World` runtime root with three children:

- `Compound`, the persistent facility scene;
- `Players`, the actor container; and
- `Round`, the active Experiment scene container.

On startup, `Game.gd` loads a requested Puzzle, PVE, or PVP Round, maps it to the corresponding Laboratory, moves the `Round` root to that Laboratory's anchor, and creates one local `Player`. The Compound remains instantiated when the active Round changes. There is no menu, lobby scene, UI, network peer, `MultiplayerSpawner`, or `MultiplayerSynchronizer` in the runtime.

## Compound And Environment Kit

`scenes/environment/Compound.tscn` is the persistent faceted-hemisphere greybox. It contains the Central Core, elevated annular Assignment Deck, reserved Researcher booth position, three inward-facing 52 m Test Floors, separator spines, normal-Round shutters, and the twelve-module perimeter maintenance route. Each Laboratory owns three Landing-strategy markers, a dominant apparatus silhouette, geometry/icon/motion critical-state cues, a sightline hook into the Assignment Deck, and a stable `RoundContent` boundary. `Compound.set_laboratory_critical_state()` drives all three non-colour cue channels together.

`scenes/environment/EnvironmentKitPiece.tscn` is the reusable environment-kit primitive. `EnvironmentKitPiece.gd` builds its replaceable `Visual` and Godot-owned `GameplayCollision` children from metre-scale dimensions using a floor-centred origin. The kit catalogues orthogonal floor and wall bays, radial and annular segments, dome-shell bays, spine junctions, 4 m door frames and shutters, deck rails, columns, trusses, vents, and panels. Compound instances use stable sequence names and store their kind, dimensions, grid increment, and origin contract as metadata for validation and future tooling.

Normal-Round confinement is a selection operation on the persistent Compound. `Compound.select_active_laboratory()` enables only the selected Laboratory's `RoundContent` processing and keeps both of its route shutters closed. It does not hide, free, duplicate, or reset any Laboratory, so authored scene state remains attached to the original nodes.

`EnvironmentKitPiece` and `PuzzleUnit` detach their runtime-created `Mesh` resources from `MeshInstance3D` children during tree exit. Procedural render owners preserve this teardown boundary so Godot 4.3 unregisters each render instance before its final mesh resource reference is released.

## Autoload Services

| Service | Current responsibility |
| --- | --- |
| `VerbChainManager` | Registers Players and Verbs, forms and dissolves two-Subject or Self-Chains, and calculates synergy and versatility values. |
| `ScoreManager` | Stores Subject-owned Round Scores and cumulative Trial Scores, exposes Trial Ranking, and provides lowest-score-first draft ordering. |
| `RoundManager` | Uses a Trial seed to select authored Experiment Protocols without replacement, tracks the current Round, and gates Player-versus-Player Impacts using each Protocol's internal classification. |
| `LobbyManager` | Tracks the roster, unique Verb claims, timed Verb Selection, Pair Draft order, and shared insertion-platform occupancy. |
| `CollapseManager` | Resolves individual First Place, starts the Collapse for a tie, applies universal Overdrive, and declares the final survivor. |

These are stateful in-process services. Comments identify intended RPC and replication boundaries, but the methods and signals currently execute locally.

## Actors And Interaction

`Player.gd` is a third-person `CharacterBody3D` controller with camera-relative movement, jumping, a basic fist Impact, a tether penalty, nine Verbs, and timed buffs. Every Subject has baseline Stability, configurable per-Verb Expression Costs, a 1-Stability self-spend floor, Critical Stability hooks, external-Impact Destabilisation, and normal-Experiment Restabilisation. Subjects and Residuals shed configurable Material on Impact and Destabilisation. A live Subject below baseline absorbs Material on contact to Restabilise without exceeding baseline.

`Residual.gd` is a pursuing `CharacterBody3D`. It finds the nearest stable Subject, attacks in range, and scales over time. A per-Residual seeded survival threshold develops one Adverb that modifies movement, attacks, and any assumed Verb; Destabilising a Subject is the only path to assuming one Verb. Separate mesh layers present the standard Verb colour treatment and a neutral Adverb overlay. PVE code addresses these actors through the `residuals` group.

Subject and Residual scenes own gameplay collision separately from a replaceable `Visual` subtree. `AnimationAdapter` translates movement, jump, landing, Impact, Verb Expression, Stability-loss, and Destabilisation events into the semantic animation names documented by the visual asset pipeline. The adapter is the sole presentation-side owner of basic-hit contact: the proxy fallback resolves at full extension, a production `basic_hit` clip may mark its authored contact frame through the adapter, and an unmarked production clip falls back at the end of its duration. Each accepted presentation attempt can emit at most one gameplay Impact. Production scenes may replace the visual subtree and `AnimationPlayer` without changing gameplay scripts.

The implemented input map is WASD movement, Space jump, left mouse basic hit, right mouse Verb use, and Escape mouse capture.

## Experiments

Experiment Protocols are authored resources containing an Objective, hazards, scoring rules, completion condition, and an internal development classification. The Semantic Engine authority in `RoundManager` selects a deterministic three-Protocol sequence from a Trial seed and derives each Experiment Brief from the selected resource.

`PuzzleRound` executes the Precision Assembly Protocol. It scatters five physics puzzle units, dispenses Material through a visible Semantic Engine apparatus, and ranks Players by completed-unit contributions. Dispensing stops while the Semantic Engine is offline during the Collapse. The available units are:

- Momentum Turbine;
- Counterweight Plate;
- Wrecking Pendulum;
- Gravity Funnel; and
- Domino Tower.

`PuzzleUnit` provides shared contribution tracking, Verb power modifiers, completion signals, and helpers for procedural physics bodies.

`PVERound` executes the Adaptive Containment Protocol. It spawns increasingly frequent and strong hostile waves around living Players. It scores kills and survival ticks, supplies deterministic per-Residual grammar seeds, and transfers a Destabilised Player's Verb to the responsible hostile.

`PVPRound` executes the Competitive Stress Protocol in an open impact crucible with measurement pylons, force plates, launch markings, shelters, and barricades. It samples Subject-owned dominance, displacement, and resilience metrics, awards knockout bonuses, and Recalls Destabilised Subjects.

All three Round controllers emit an ordered list when asked to end. None controls the complete three-Round Trial lifecycle from the main scene.

## Scene And State Boundaries

| Layer | Owns | Does not own |
| --- | --- | --- |
| `Game` | Scene composition, persistent Compound instance, active Round placement, local Player instance | Laboratory geometry internals, scoring formulas, Pair rules, actor behaviour |
| `Compound` | Facility topology, environment-kit instances, Laboratory anchors, normal-Round spatial confinement | Experiment objectives, spawning, scoring, Trial lifecycle |
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
- the Compound, Assignment Deck, three Laboratories, separator shutters, and perimeter route have a locally runnable structural greybox;
- the Dispensing Line, Drop, Recall, Result Announcement, and Thematic Moments remain design contracts only; and
- multiplayer transport, replication, deterministic scenarios, UI, audio, production art, and comprehensive automated gameplay coverage are absent.

GitHub issues own implementation work. This document records capability boundaries only.

## Dependencies And Extension Rules

- Keep the main scene as a composition root; domain calculations belong in services or focused domain objects.
- Keep Round-local nodes and cleanup inside Round scenes.
- Keep server-authoritative decisions separate from presentation when networking is introduced.
- Do not treat RPC comments as implemented networking guarantees.
- Preserve the integer ordering of `Enums.VerbType`; append new values because the values are intended for serialisation.
- Keep gameplay collision in Godot scenes and presentation assets replaceable behind stable scene boundaries.
