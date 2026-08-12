# Architecture

[`CONTEXT.md`](../CONTEXT.md) defines canonical product rules and domain language. This document describes the software currently present in the repository. Names in backticks are literal code identifiers, including identifiers that do not yet match the domain language.

## Runtime

VerbEndings is a Godot 4.3 project using Forward Plus rendering. `scenes/core/Game.tscn` is the configured main scene. Its `Game` script owns the `World` runtime root with three children:

- `Compound`, the persistent facility scene;
- `Players`, the actor container; and
- `Round`, the active Experiment scene container.

On startup, `Game.gd` reads `resources/local_playtest.tres`, resets the in-process Trial services, registers the configured roster through `LobbyManager`, and assigns deterministic unique Verbs. Local automatic selections share a zero-duration pick time, so Round One uses the stable Subject-id tie-break instead of machine scheduling time. `TrialCoordinator` then runs the canonical three-Round lifecycle and asks `Game` to compose each selected Protocol's Round scene in its Laboratory. One Subject accepts local input; optional additional Subjects are stationary participants. Same-seed and next-seed restart actions rebuild the roster, lifecycle, Round, scores, and seeded global random stream without replacing the persistent Compound. There is no menu, lobby scene, UI, network peer, `MultiplayerSpawner`, or `MultiplayerSynchronizer` in the runtime.

## Compound And Environment Kit

`scenes/environment/Compound.tscn` is the persistent faceted-hemisphere greybox. It contains the Central Core, elevated annular Assignment Deck, reserved Researcher booth position, three inward-facing 52 m Test Floors, separator spines, normal-Round shutters, and the twelve-module perimeter maintenance route. Each Laboratory owns three Landing-strategy markers, a dominant apparatus silhouette, geometry/icon/motion critical-state cues, a sightline hook into the Assignment Deck, and a stable `RoundContent` boundary. `Compound.set_laboratory_critical_state()` drives all three non-colour cue channels together.

`scenes/environment/EnvironmentKitPiece.tscn` is the reusable environment-kit primitive. `EnvironmentKitPiece.gd` builds its replaceable `Visual` and Godot-owned `GameplayCollision` children from metre-scale dimensions using a floor-centred origin. The kit catalogues orthogonal floor and wall bays, radial and annular segments, dome-shell bays, spine junctions, 4 m door frames and shutters, deck rails, columns, trusses, vents, and panels. Compound instances use stable sequence names and store their kind, dimensions, grid increment, and origin contract as metadata for validation and future tooling.

Normal-Round confinement is a selection operation on the persistent Compound. `Compound.select_active_laboratory()` enables only the selected Laboratory's `RoundContent` processing and keeps both of its route shutters closed. It does not hide, free, duplicate, or reset any Laboratory, so authored scene state remains attached to the original nodes.

`EnvironmentKitPiece` detaches old children before building their replacements so a live rebuild cannot attach new gameplay collision beneath a node queued for deletion. `EnvironmentKitPiece` and `PuzzleUnit` also detach their runtime-created `Mesh` resources from `MeshInstance3D` children during tree exit. Procedural render owners preserve this teardown boundary so Godot 4.3 unregisters each render instance before its final mesh resource reference is released.

## Autoload Services

| Service | Current responsibility |
| --- | --- |
| `VerbChainManager` | Registers Players and Verbs, forms and dissolves two-Subject or Self-Chains, calculates synergy and versatility values, pushes Overdrive state onto Self-Chained actors, and Severs a live Pair when one Partner is Eliminated. A Severed bond is removed immediately while its Round-scoped Chain record remains available for symmetric scoring until scheduled dissolution. |
| `ScoreManager` | Stores Subject-owned Round Scores and cumulative Trial Scores, exposes competition-ranked Trial Ranking, applies each Protocol's authored individual or Verb-Chain reward policy, and provides lowest-Trial-Score-first draft ordering. Shared rewards credit each Partner separately, optionally use the Synergy Coefficient, and pay a Self-Chain once without Synergy scaling. Its placement and bonus tables are keyed by development classification. |
| `RoundManager` | Uses a Trial seed to shuffle the three authored Experiment Protocols into a host-only queue, plays one per Round without replacement, announces at each transition which classification left the pool, derives banner text from the selected Protocol, and gates Player-versus-Player Impacts using that Protocol's internal classification. |
| `LobbyManager` | Tracks the roster, unique Verb claims, timed Verb Selection, Pair Draft turn order, forced Self-Chains for an odd roster, and shared insertion-platform occupancy. Round One drafts slowest-Verb-pick-first; later Rounds use `ScoreManager`'s lowest-Trial-Score-first order. |
| `CollapseManager` | Resolves individual First Place, starts the Collapse for the Subjects tied at First Place, applies Overdrive to those participants, and declares the final survivor. |
| `TrialCoordinator` | Owns the host-authoritative Trial state machine: Verb Selection once; Pair Draft, Experiment Brief, Laboratory Entry, timed or condition-completed Experiment, Recall, Result Announcement, and optional Thematic Moment for each of exactly three Rounds; then sole-winner or Collapse resolution. It emits presentation-independent state and composition signals. |

These are stateful in-process services. Comments identify intended RPC and replication boundaries, but the methods and signals currently execute locally.

## Actors And Interaction

`Player.gd` is a third-person `CharacterBody3D` controller with camera-relative movement, jumping, a basic fist Impact, a tether penalty, nine Verbs, and timed buffs. Every Subject has baseline Stability, configurable per-Verb Expression Costs, configurable Severance Loss with a 1-Stability floor, a 1-Stability self-spend floor, Critical Stability hooks, external-Impact Destabilisation, a configurable always-on Stabilisation Rate expressed as a percentage of baseline per second, and full Restabilisation at Recall. Subjects and Residuals shed configurable Material on Impact and Destabilisation. A live Subject below baseline absorbs Material on contact to Restabilise without exceeding baseline.

`Residual.gd` is a pursuing `CharacterBody3D`. It finds the nearest stable Subject, attacks in range, and scales over time. A per-Residual seeded survival threshold develops one Adverb that modifies movement, attacks, and any assumed Verb; Destabilising a Subject is the only path to assuming one Verb. Separate mesh layers present the standard Verb colour treatment and a neutral Adverb overlay. PVE code addresses these actors through the `residuals` group.

Subject and Residual scenes own gameplay collision separately from a replaceable `Visual` subtree. `AnimationAdapter` translates movement, jump, landing, Impact, Verb Expression, Stability-loss, and Destabilisation events into the semantic animation names documented by the visual asset pipeline. The adapter is the sole presentation-side owner of basic-hit contact: the proxy fallback resolves at full extension, a production `basic_hit` clip may mark its authored contact frame through the adapter, and an unmarked production clip falls back at the end of its duration. Each accepted presentation attempt can emit at most one gameplay Impact. Production scenes may replace the visual subtree and `AnimationPlayer` without changing gameplay scripts.

`scenes/MaterialDispenser.tscn` follows the same boundary: the scene owns gameplay, the Godot cylinder collision, and the `DispenseSocket`, while an imported GLB child named `Visual` owns presentation. Broader production art remains incomplete.

The implemented input map is WASD movement, Space jump, left mouse basic hit, right mouse Verb use, and Escape mouse capture.

## Experiments

Experiment Protocols are authored resources containing an Objective, hazards, scoring rules, completion condition, and an internal development classification. Scoring rules declare whether placements are individual or Verb-Chain-shared, which bonus events are cooperative, and whether shared rewards use the Synergy Coefficient. Round controllers submit Subject performance order and bonus events through `ScoreManager`, which applies that authored policy while retaining Subject-owned Round Scores and Trial Scores. The Semantic Engine authority in `RoundManager` selects a deterministic three-Protocol sequence from a Trial seed and derives each Experiment Brief from the selected resource.

`EnvironmentRound` executes the Sustained Exposure Protocol in the Applied Attrition Laboratory. It applies configurable continuous atmospheric Stability Loss through the Subject hazard path, suppressing Impact shedding so only the Semantic Engine and authored housings supply Material. It records each Subject's survival time and Material absorbed, ranks an authored weighted blend of both measures, then pays placement through each Verb Chain with Synergy scaling. Two elevated dispensers require named traversal routes, and two breakable hero-prop housings provide a damage route to Material. Dispensing stops while the Semantic Engine is offline during the Collapse.

The controller scatters at least one of each of the following physics apparatuses as obstacles and traversal tools:

- Momentum Turbine;
- Counterweight Plate;
- Wrecking Pendulum;
- Gravity Funnel; and
- Domino Tower.

`PuzzleUnit` provides Verb power modifiers, internal apparatus progress, and helpers for procedural physics bodies. Apparatus interaction does not track contributors, award points, or complete the Experiment. The Sustained Exposure Protocol authors a hazard, route, or housing answer for each of the nine Verbs.

`PVERound` executes the Adaptive Containment Protocol. It spawns increasingly frequent and strong hostile waves around living Players. It pays placement and Residual Destabilisation bonuses through the Verb Chain with Synergy scaling, keeps survival ticks individual, supplies deterministic per-Residual grammar seeds, and transfers a Destabilised Player's Verb to the responsible hostile.

`PVPRound` executes the Competitive Stress Protocol in an open impact crucible with measurement pylons, force plates, launch markings, shelters, and barricades. It samples Subject-owned dominance, displacement, and resilience metrics, awards knockout bonuses, and Recalls Destabilised Subjects.

All three Round controllers emit an ordered list when asked to end. None controls the complete three-Round Trial lifecycle from the main scene.

## Scene And State Boundaries

| Layer | Owns | Does not own |
| --- | --- | --- |
| `Game` | Scene composition, persistent Compound instance, deterministic local bootstrap, local Subject instances, and active Round placement | Laboratory geometry internals, scoring formulas, Pair rules, actor behaviour |
| `Compound` | Facility topology, environment-kit instances, Laboratory anchors, normal-Round spatial confinement | Experiment objectives, spawning, scoring, Trial lifecycle |
| Autoload services | Cross-scene roster, chain, score, Round, and final-resolution state | Render geometry and per-frame actor simulation |
| Round controllers | Experiment-local spawning, scoring inputs, ordering, cleanup | Verb Selection and persistent Trial presentation |
| Actors | Input, movement, Impacts, Verb effects, actor-local state | Trial ranking and Round selection |
| Environment apparatus | One physics interaction and its local state | Subject contribution tracking, global score and Trial state |

## Current Capability Boundary

The repository provides a deterministic local gameplay quick start and a presentation-independent canonical three-Round lifecycle. The following capability boundaries remain:

- Material dispensing and breakable Material housings are wired into Sustained Exposure; other Experiments rely on Impact shedding;
- the Pair Draft has entry points for all three Rounds;
- the local quick start configures one Protocol and a roster of one locally controlled Subject plus optional stationary participants; it is isolated from the unimplemented production host/join path;
- the insertion platform is not the canonical Drop sequence, and no Round scene instances it;
- Trial resolution uses individual Trial Scores and starts the Collapse for tied First Place; the local runtime automatically advances the complete three-Round lifecycle, while physical Drop, Recall, announcement, and Thematic Moment presentation remain unimplemented;
- the full Compound-wide Collapse environment and Residual pacing are not implemented;
- development classifications still key the scoring tables and travel in `RoundManager`'s transition signal, so any consumer of that signal must keep them out of player-facing text;
- Material shedding and Environment apparatus scatter positions use the global random stream, which the local quick start seeds from the Trial seed but multiplayer authority does not yet replicate;
- the Compound, Assignment Deck, three Laboratories, separator shutters, and perimeter route have a locally runnable structural greybox;
- the Dispensing Line, Drop, Recall and Result Announcement presentation, and Thematic Moments remain design contracts only; and
- multiplayer transport, replication, deterministic scenarios, UI, audio, production art beyond the Material Dispenser visual, and comprehensive automated gameplay coverage are absent.

Focused headless gameplay suites cover Overdrive, Stability, Trial resolution, Residual grammar, Experiment Protocols, the animation adapter, the Material Dispenser visual boundary, and the Compound greybox; `docs/VALIDATION.md` records how to run them.

GitHub issues own implementation work. This document records capability boundaries only.

## Non-Canonical Identifiers

Several code identifiers and internal comments do not match `CONTEXT.md`. They are load-bearing today, so the mismatch is recorded here rather than hidden:

- `Player`, `player_id`, `players` group, and `active_players` stand for Subject and Subject identity;
- `InsertionVector`, `insertion_vector_launched`, and vector occupancy in `LobbyManager` stand in for the Dispensing Line and the Drop; and
- `swarm_kill` is a serialised bonus key in the `adaptive_containment` Protocol resource and `ScoreManager.BONUS_EVENTS`, so the string stays until a data migration renames it.

## Dependencies And Extension Rules

- Keep the main scene as a composition root; domain calculations belong in services or focused domain objects.
- Keep Round-local nodes and cleanup inside Round scenes.
- Keep server-authoritative decisions separate from presentation when networking is introduced.
- Do not treat RPC comments as implemented networking guarantees.
- Preserve the integer ordering of `Enums.VerbType`; append new values because the values are intended for serialisation.
- Keep gameplay collision in Godot scenes and presentation assets replaceable behind stable scene boundaries.
