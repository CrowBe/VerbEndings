# Architecture

[`CONTEXT.md`](../CONTEXT.md) defines canonical product rules and domain language. This document describes the software currently present in the repository. Names in backticks are literal code identifiers, including identifiers that do not yet match the domain language.

## Runtime

VerbEndings is a Godot 4.3 project using Forward Plus rendering. `scenes/core/Game.tscn` is the configured main scene. Its `Game` script owns the `World` runtime root with four children:

- `Compound`, the persistent facility scene;
- `Players`, the actor container; and
- `Round`, the active Experiment scene container; and
- `LaboratoryTransit`, the presentation controller container for Drop and Recall.

On startup, `Game.gd` presents the main menu through `TrialPresentation`. A local Trial reads `resources/local_playtest.tres`, resets the in-process Trial services, registers the configured roster through `LobbyManager`, and collects timed unique Verb claims before starting. The F5 developer quick start remains available and assigns deterministic unique Verbs automatically; its zero-duration picks use the stable Subject-id tie-break for Round One. `TrialCoordinator` then runs the canonical three-Round lifecycle and asks `Game` to compose each selected Protocol's Round scene in its Laboratory. Interactive Trials wait for the presentation to acknowledge each Experiment Brief and Result Announcement, while automated test and quick-start Trials advance those boundaries directly. `LaboratoryTransit` presents the internal Dispensing Line journey as a cut, holds each Subject at its overhead Drop socket until independent Release, returns normal movement for steerable descent, waits for every Landing, and lifts Subjects through floor apertures during Recall. One Subject accepts local input; optional additional local Subjects Release automatically and remain stationary after Landing. Same-seed and next-seed restart actions rebuild the roster, lifecycle, Round, transit, scores, and seeded global random stream without replacing the persistent Compound.

When Round Three ends in tied First Place, `CollapseManager` creates a seeded, server-authoritative entry and failure plan for the eligible Subjects. `Game` composes that plan across the persistent Compound: tied Subjects enter unique fair sockets, non-participants leave play, the Assignment Deck seals for a protected orientation window, the perimeter and separator routes open, dangerous Core shortcuts follow, and warned Laboratory failure volumes activate through facility-ledger transitions. Destabilisation is permanent during this phase. Eliminations reported in one frame resolve as a batch by survival time and then stable Subject id.

The main menu exposes local, host, and join flows over `Game.host_session()` and `Game.join_session()`. `TrialPresentation` submits the owning peer's Verb and Pair Draft choices through `NetworkSession`; the host remains authoritative and starts the Trial after every connected Subject has a unique Verb. `NetworkSession` enrols peers into the same domain services, accepts movement and action intent from owning clients, simulates gameplay on the host, and sends explicit snapshots for roster, revealed lifecycle state, Pair state, scores, Collapse state, Subjects, Residuals, and the owning HUD's Verb Expression cooldown. The host's secret Protocol queue is never included. Clients compose the revealed Round and render replicated actors without advancing Round simulation. There is no separate lobby scene, matchmaking or discovery service, `MultiplayerSpawner`, or `MultiplayerSynchronizer`; explicit replication is the implemented equivalent transport boundary.

`TrialPresentation` is a replaceable `CanvasLayer` boundary over the persistent 3D world. It renders menu and connection controls, the timed Verb list, Pair Draft turn and Partner choices, classification-free Experiment Briefs and banners, Drop and Recall prompts, Result Announcements, and the final winner. During an Experiment its HUD shows the authored Objective, remaining Verb Expression cooldown, Stability, individual Round Score, and a text-and-shape Critical Stability cue. A compact build-and-seed strip opens a copyable diagnostics view without obscuring normal play. Rankings always come from `ScoreManager` and remain Subject-owned.

The supported external playtest artefact is a Linux x86_64 release export containing the executable, adjacent PCK, and tester runbook. `tools/check_export.py` creates the runtime files with Godot 4.3, copies the runbook, and launches the exported main menu through a bounded smoke check. CI runs the same check and publishes the playtest package as an artefact.

## Compound And Environment Kit

`scenes/environment/Compound.tscn` is the persistent faceted-hemisphere greybox. It contains the Central Core, elevated annular Assignment Deck, a 24-tube overhead Dispensing Line, reserved Researcher booth position, three inward-facing 52 m Test Floors, separator spines, normal-Round shutters, and the twelve-module perimeter maintenance route. Each Laboratory owns 24 overhead Drop sockets, 24 floor Recall apertures, three Landing-strategy markers, a dominant apparatus silhouette, geometry/icon/motion critical-state cues, a sightline hook into the Assignment Deck, and a stable `RoundContent` boundary. Sequential tube indices are physically adjacent, and the matching index identifies one Subject's Drop and Recall path. `Compound.set_laboratory_critical_state()` drives all three non-colour cue channels together. Adaptive Containment's `RoundContent` also owns seven named Residual entry fixtures across its specimen column, perimeter pens, vents and wall cavities, plus Subject-operated bait machinery, paired emergency shutter controls and a defensive power node.

`scenes/environment/EnvironmentKitPiece.tscn` is the reusable environment-kit primitive. `EnvironmentKitPiece.gd` builds its replaceable `Visual` and Godot-owned `GameplayCollision` children from metre-scale dimensions using a floor-centred origin. The kit catalogues orthogonal floor and wall bays, radial and annular segments, dome-shell bays, spine junctions, 4 m door frames and shutters, deck rails, columns, trusses, vents, and panels. Compound instances use stable sequence names and store their kind, dimensions, grid increment, and origin contract as metadata for validation and future tooling.

Normal-Round confinement is a selection operation on the persistent Compound. `Compound.select_active_laboratory()` enables only the selected Laboratory's `RoundContent` processing and keeps both of its route shutters closed. It does not hide, free, duplicate, or reset any Laboratory, so authored scene state remains attached to the original nodes.

`FacilityStateLedger` is the server-authoritative presentation-state boundary for the persistent Compound. For each Laboratory it composes Round stage, persistent prop and structural-surface state, Experiment lifecycle, and compatible event overlays. Every state-changing transition has a stable name and seed-derived token. Structural walls and floors expose cosmetic state only; selected props declare ordered authored thresholds, explicit collision state, and any route they block. The ledger rejects backwards threshold changes, loss of the final valid route, conflicting overlay channels, overlays that repair persistent state, and changes that contradict an active Objective or overlay. Trial reset restores the authored baseline, while Round changes retain prior Laboratory state. The host includes the current composed ledger and transition sequence, but not its historical log, in explicit network snapshots; clients apply the replicated composition to their persistent Compound.

The Compound exposes 24 Collapse entry sockets distributed evenly across the three Laboratories. Every socket declares comparable initial hazard exposure and two exit options. Three physical Assignment Deck seals, the twelve Laboratory route shutters, the dependable perimeter connection, and three authored failure volumes are composed by `CollapseComposition`, which owns the one mapping from Collapse stage to facility state. The host applies each stage as `CollapseManager` announces it, a client composes every stage its replicated snapshot has already reached, and both paths are idempotent. `Compound` receives the survivor list and Subject bodies as arguments and reads no Collapse state itself. A failure first raises the Laboratory's geometry, icon and motion warning hooks, then records the structural and apparatus transition in `FacilityStateLedger` before its hazard becomes active.

`EnvironmentKitPiece` detaches old children before building their replacements so a live rebuild cannot attach new gameplay collision beneath a node queued for deletion. `EnvironmentKitPiece` and `PuzzleUnit` also detach their runtime-created `Mesh` resources from `MeshInstance3D` children during tree exit. Procedural render owners preserve this teardown boundary so Godot 4.3 unregisters each render instance before its final mesh resource reference is released.

## Autoload Services

| Service | Current responsibility |
| --- | --- |
| `SubjectRoster` | Binds a Subject id to its live body and owns the operations services previously performed by walking the scene tree: Self-Chain, Partnered, Unpaired and Solo-Overdrive chain state, Severance Loss, Recall Restabilisation, Collapse removal from play, and `destabilised` signal wiring. Overdrive is granted and cleared only through this service. |
| `NetworkSession` | Creates ENet host and client peers, enrols and releases connected Subjects, validates sender-bound Verb, Pairing, movement, Release, Impact, and Verb Expression requests, and routes host-authored state snapshots without disclosing the secret Protocol queue. Each replicated module composes and applies its own state, so the transport holds no field layouts and emits no domain signals. |
| `VerbChainManager` | Registers Players and Verbs, forms and dissolves two-Subject or Self-Chains, calculates synergy and versatility values, pushes Overdrive state onto Self-Chained actors, and Severs a live Pair when one Partner is Eliminated. A Severed bond is removed immediately while its Round-scoped Chain record remains available for symmetric scoring until scheduled dissolution. |
| `ScoreManager` | Stores Subject-owned Round Scores and cumulative Trial Scores, exposes competition-ranked Trial Ranking, applies each Protocol's authored individual or Verb-Chain reward policy, and provides lowest-Trial-Score-first draft ordering. Shared rewards credit each Partner separately, optionally use the Synergy Coefficient, and pay a Self-Chain once without Synergy scaling. Its placement and bonus tables are keyed by development classification. |
| `RoundManager` | Uses a Trial seed to shuffle the three authored Experiment Protocols into a host-only queue, plays one per Round without replacement, announces at each transition which classification left the pool, derives banner text from the selected Protocol, and gates Player-versus-Player Impacts using that Protocol's internal classification. |
| `LobbyManager` | Tracks the roster, unique Verb claims, timed Verb Selection, Pair Draft turn order, forced Self-Chains for an odd roster, and deterministic Dispensing Line tube assignments. It answers whether Verb Selection is complete, so no caller reconstructs that from the roster and Verb registry. A Pair receives adjacent tubes and a Self-Chain receives one tube. Round One drafts slowest-Verb-pick-first; later Rounds use `ScoreManager`'s lowest-Trial-Score-first order. |
| `CollapseManager` | Resolves individual First Place; creates seeded fair entry and Laboratory-failure plans; advances protected orientation, route, Core-shortcut and warned-failure stages; batches simultaneous Eliminations; applies Overdrive; and declares the final survivor. |
| `FacilityStateLedger` | Records and validates seeded, named transitions across the four Compound presentation layers, retains authored Laboratory state for the Trial, and supplies the host-authored snapshot consumed by clients. |
| `TrialCoordinator` | Owns the host-authoritative Trial state machine: Verb Selection once; Pair Draft, Experiment Brief, Laboratory Entry, timed or condition-completed Experiment, Recall, Result Announcement, and optional Thematic Moment for each of exactly three Rounds; then sole-winner or Collapse resolution. It emits presentation-independent state and composition signals. |
| `SessionDiagnostics` | Records a bounded, privacy-safe local summary of build and seed identity, revealed Protocol order, lifecycle transitions, Subject disconnects, and final result; persists the latest JSON summary under `user://` for the presentation to display and copy. |

The domain services are stateful and in-process. `NetworkSession` is their transport boundary: only the host mutates canonical networked state, while local quick start continues to call the same services without a multiplayer peer. Every replicated module exposes a `snapshot()` and `apply_replicated_state()` pair and announces its own transitions on each peer.

`NetworkSession` also answers the session's authority questions. `can_simulate()` is true for a local Trial and the host and gates every simulation and lifecycle decision; `is_client()` and `is_local()` distinguish the remaining cases; `is_host()` covers transport work alone. No caller re-derives authority from the multiplayer peer. Host actor snapshots include each Residual's authored entry identity and visibility while it crosses a fixture, and transient containment-tool timers, so clients present the same entry and tool state without simulating either effect.

## Actors And Interaction

`Player.gd` is a third-person `CharacterBody3D` controller with camera-relative movement, jumping, a basic fist Impact, a tether penalty, nine Verbs, and timed buffs. In a network session the owning client submits bounded intent and the host performs physics, Impacts, Verb Expressions, Stability changes, and cooldown validation. Remote transforms and gameplay state are explicit snapshots. Every Subject has baseline Stability, configurable per-Verb Expression Costs, configurable Severance Loss with a 1-Stability floor, a 1-Stability self-spend floor, Critical Stability hooks, external-Impact Destabilisation, a configurable always-on Stabilisation Rate expressed as a percentage of baseline per second, and full Restabilisation at Recall. Subjects and Residuals shed configurable Material on Impact and Destabilisation. A live Subject below baseline absorbs Material on contact to Restabilise without exceeding baseline.

`Residual.gd` is a pursuing `CharacterBody3D`. It finds the nearest stable Subject, attacks in range, and scales over time. A per-Residual seeded survival threshold develops one Adverb that modifies movement, attacks, and any assumed Verb; Destabilising a Subject is the only path to assuming one Verb. Separate mesh layers present the standard Verb colour treatment and a neutral Adverb overlay. PVE code addresses these actors through the `residuals` group.

Subject and Residual scenes own gameplay collision separately from a replaceable `Visual` subtree. `AnimationAdapter` translates movement, jump, landing, Impact, Verb Expression, Stability-loss, and Destabilisation events into the semantic animation names documented by the visual asset pipeline. The adapter is the sole presentation-side owner of basic-hit contact: the proxy fallback resolves at full extension, a production `basic_hit` clip may mark its authored contact frame through the adapter, and an unmarked production clip falls back at the end of its duration. Each accepted presentation attempt can emit at most one gameplay Impact. Production scenes may replace the visual subtree and `AnimationPlayer` without changing gameplay scripts.

`scenes/MaterialDispenser.tscn` follows the same boundary: the scene owns gameplay, the Godot cylinder collision, and the `DispenseSocket`, while an imported GLB child named `Visual` owns presentation. Broader production art remains incomplete.

The implemented input map is WASD movement, Space jump, left mouse basic hit, right mouse Verb use, and Escape mouse capture.

## Experiments

`ExperimentController` is the base class for every Protocol controller and owns the lifecycle contract `TrialCoordinator` depends on: Subject registration, canonical Elimination, Chain Severance for an Eliminated Subject outside the Collapse, reporting when one Subject is left standing, placement ordering by performance with a stable Subject-id tie-break, and submitting placements before announcing the result. A subclass supplies its authored Protocol, per-Subject measurements, and any Protocol-specific consequence of an Elimination. A Destabilised Subject is out of the Experiment and stays down; `TrialCoordinator` Recalls every Subject to baseline Stability at the end of the Round.

Experiment Protocols are authored resources containing an Objective, hazards, scoring rules, completion condition, and an internal development classification. Scoring rules declare whether placements are individual or Verb-Chain-shared, which bonus events are cooperative, and whether shared rewards use the Synergy Coefficient. Round controllers submit Subject performance order and bonus events through `ScoreManager`, which applies that authored policy while retaining Subject-owned Round Scores and Trial Scores. The Semantic Engine authority in `RoundManager` selects a deterministic three-Protocol sequence from a Trial seed and derives each Experiment Brief from the selected resource.

`EnvironmentRound` executes the Sustained Exposure Protocol in the Applied Attrition Laboratory. It applies configurable continuous atmospheric Stability Loss through the Subject hazard path, suppressing Impact shedding so only the Semantic Engine and authored housings supply Material. It records each Subject's survival time and Material absorbed, ranks an authored weighted blend of both measures, then pays placement through each Verb Chain with Synergy scaling. Two elevated dispensers require named traversal routes, and two breakable hero-prop housings provide a damage route to Material. Dispensing stops while the Semantic Engine is offline during the Collapse.

The controller scatters at least one of each of the following physics apparatuses as obstacles and traversal tools:

- Momentum Turbine;
- Counterweight Plate;
- Wrecking Pendulum;
- Gravity Funnel; and
- Domino Tower.

`PuzzleUnit` provides Verb power modifiers, internal apparatus progress, and helpers for procedural physics bodies. Apparatus interaction does not track contributors, award points, or complete the Experiment. The Sustained Exposure Protocol authors a hazard, route, or housing answer for each of the nine Verbs.

`PVERound` executes the Adaptive Containment Protocol. `Game` injects the persistent Compound boundary, and each increasingly frequent and strong wave stages one Residual per stable Subject through an available named physical opening; there is no positional or generic-effect fallback. Bait machinery temporarily diverts active Residuals, emergency shutters remove their linked openings from entry selection, and the defensive power node temporarily slows the encounter. It pays placement and Residual Destabilisation bonuses through the Verb Chain with Synergy scaling, keeps survival ticks individual, supplies deterministic per-Residual grammar seeds, and transfers a Destabilised Player's Verb to the responsible hostile.

`PVPRound` executes the Competitive Stress Protocol in an open impact crucible with measurement pylons, force plates, launch markings, shelters, and barricades. It samples Subject-owned dominance, displacement, and resilience metrics and awards knockout bonuses. Its authored completion mode ends the Experiment once one Subject is left standing.

All three Round controllers inherit `ExperimentController`, so each supplies only its performance measure and Elimination consequences. None controls the complete three-Round Trial lifecycle from the main scene.

## Scene And State Boundaries

| Layer | Owns | Does not own |
| --- | --- | --- |
| `Game` | Scene composition, persistent Compound instance, deterministic local bootstrap, local Subject instances, and active Round placement | Laboratory geometry internals, scoring formulas, Pair rules, actor behaviour |
| `Compound` | Facility topology, environment-kit instances, Laboratory anchors, normal-Round spatial confinement | Experiment objectives, spawning, scoring, Trial lifecycle |
| Autoload services | Cross-scene roster, chain, score, Round, and final-resolution state, plus the Subject id-to-body binding | Render geometry and per-frame actor simulation |
| Round controllers | Experiment-local spawning, scoring inputs, ordering, cleanup | Verb Selection and persistent Trial presentation |
| Actors | Input, movement, Impacts, Verb effects, actor-local state | Trial ranking and Round selection |
| Environment apparatus | One physics interaction and its local state | Subject contribution tracking, global score and Trial state |
| `TrialPresentation` | Menu and connection input, lifecycle screens, banners, HUD, build/seed diagnostics, summary copying, and presentation acknowledgements | Roster authority, scoring, Pair validation, Protocol selection, actor simulation |

## Current Capability Boundary

The repository provides a deterministic local gameplay quick start and a presentation-independent canonical three-Round lifecycle. The following capability boundaries remain:

- Material dispensing and breakable Material housings are wired into Sustained Exposure; other Experiments rely on Impact shedding;
- the Pair Draft has entry points for all three Rounds;
- the player-facing local flow and developer quick start share one configured roster of one locally controlled Subject plus optional stationary participants; network sessions use manual host address and port entry without matchmaking or discovery;
- Trial resolution uses individual Trial Scores, presents Round Scores and Trial Ranking after each Recall, and starts the Collapse for tied First Place; Thematic Moment presentation remains unimplemented;
- the Compound-wide Collapse uses seeded entry sockets, a protected orientation window, staged perimeter and Core access, authored Laboratory failure hazards, and deterministic simultaneous-Elimination resolution; its failure cadence remains configurable and production hazard presentation remains incomplete;
- development classifications still key the scoring tables and travel in `RoundManager`'s transition signal, so any consumer of that signal must keep them out of player-facing text;
- Material shedding and Environment apparatus scatter positions use the host's seeded global random stream; clients consume replicated gameplay outcomes rather than reproducing those draws;
- the Compound, Assignment Deck, three Laboratories, separator shutters, and perimeter route have a locally runnable structural greybox;
- the Dispensing Line, Drop, Recall, and Result Announcement have structural greybox presentation; tube interiors use a presentation cut, and Thematic Moments remain a design contract only; and
- seeded 12- and 24-Subject capacity scenarios validate Compound entry and replicated Collapse state, while the complete canonical lifecycle is covered at the current nine-unique-Verb ceiling and by a real two-peer ENet scenario; a 24-peer soak, reconnect support, latency compensation, audio, production art beyond the Material Dispenser visual, and comprehensive automated gameplay coverage are absent.

Focused headless gameplay suites cover Overdrive, Stability, the shared Experiment lifecycle, Trial resolution, player-facing Trial presentation, Laboratory Entry/Drop/Recall, seeded 8-, 9-, 12-, and 24-Subject lifecycle or capacity scenarios, the Compound-wide Collapse and its client catch-up composition, two-process ENet authority and disconnect handling, Residual grammar, Experiment Protocols, the facility state ledger, the animation adapter, the Material Dispenser visual boundary, and the Compound greybox; `docs/VALIDATION.md` records how to run them.

GitHub issues own implementation work. This document records capability boundaries only.

## Non-Canonical Identifiers

Several code identifiers and internal comments do not match `CONTEXT.md`. They are load-bearing today, so the mismatch is recorded here rather than hidden:

- `Player`, `player_id`, `players` group, and `active_players` stand for Subject and Subject identity;
- `swarm_kill` is a serialised bonus key in the `adaptive_containment` Protocol resource and `ScoreManager.BONUS_EVENTS`, so the string stays until a data migration renames it.

## Dependencies And Extension Rules

- Keep the main scene as a composition root; domain calculations belong in services or focused domain objects.
- Keep Round-local nodes and cleanup inside Round scenes.
- Keep server-authoritative decisions separate from presentation when networking is introduced.
- Do not treat RPC comments as implemented networking guarantees.
- Preserve the integer ordering of `Enums.VerbType`; append new values because the values are intended for serialisation.
- Keep gameplay collision in Godot scenes and presentation assets replaceable behind stable scene boundaries.
