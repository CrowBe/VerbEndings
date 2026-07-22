# Verb Endings Architecture Notes

> Domain language and gameplay relationships are defined in [`CONTEXT.md`](../CONTEXT.md). This document predates parts of that agreement; where terminology conflicts, `CONTEXT.md` is authoritative and migration is tracked in [`docs/IMPLEMENTATION_ALIGNMENT.md`](IMPLEMENTATION_ALIGNMENT.md).

## Current evaluation

The initial commit is a strong graybox: the core verbs, chain scoring,
round-specific controllers, player combat, PVE enemies, and puzzle units are
already separated by gameplay domain. The biggest architectural issue was the
boot path: the project launched directly into `Player.tscn`, which bypassed the
round and world lifecycle. That made quick controller testing easy, but it would
not scale to multiplayer spawning, lobby transitions, or swapping round scenes.

## Runtime ownership

- `scenes/core/Game.tscn` is the project entry point and owns scene composition.
- `scripts/core/Game.gd` is a thin coordinator for graybox bootstrapping,
  round-scene loading, and temporary local player spawning.
- Autoloads remain stateful services only: they should own match data and rules,
  not concrete scene children.
- Round scenes own round-local objects, timers, scoring hooks, and cleanup.
- Player and enemy scenes own moment-to-moment control/combat behavior.

## Boundaries to preserve

| Layer | Owns | Should not own |
| --- | --- | --- |
| `Game` root | Scene tree composition, active round scene, temporary local spawn | Scoring formulas, verb pairing rules, individual enemy AI |
| Autoload managers | Persistent match state and rule services | Direct graybox meshes, per-frame movement, round-only node references |
| Round controllers | Round timers, spawns, round scoring events | Lobby drafting, persistent ladder storage |
| Actors | Input, movement, combat, health | Round placement awards, match progression |
| Puzzle units | Self-contained physics toy behavior and completion signals | Global score totals, player spawning |

## Near-term cleanup backlog

1. Replace temporary `Game._spawn_local_player()` with multiplayer spawn points
   and `MultiplayerSpawner` once netcode begins.
2. Add a `PVP` round scene to `Game.ROUND_SCENES` before enabling full blind
   round rotation in the root scene.
3. Introduce lightweight resource files for verb tuning and monster mutations
   if designers need to tune values without editing scripts.
4. Move HUD/banner responsibilities into a UI scene that subscribes to manager
   signals rather than printing from managers.
5. Add CI checks once a headless Godot binary is available: script parse, scene
   load smoke test, and exported build validation.
