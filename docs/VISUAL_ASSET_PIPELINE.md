# Visual Asset and Animation Pipeline

## Goals

The game should keep graybox scenes playable while art improves in parallel.
Every production asset should be replaceable without changing gameplay scripts,
and every animation should have a clear hook from the current procedural gags to
future authored animation clips.

## Directory plan

```text
assets/
  source/            # Blender/Krita/Aseprite/etc. working files, not loaded at runtime
  exports/
    characters/      # GLB/PNG exports consumed by Godot
    enemies/
    props/
    vfx/
  materials/         # Godot material resources shared by imported meshes
  animation/         # AnimationLibrary resources when split from scenes
docs/
  art/               # Briefs, style guide, contact sheets, naming references
```

Use lowercase snake_case filenames. Keep source files and exported runtime files
side by side by concept name, for example `assets/source/player_blob.blend` and
`assets/exports/characters/player_blob.glb`.

## Asset states

1. **Graybox**: primitive meshes and procedural tweens in gameplay scenes.
2. **Proxy art**: rough exported meshes preserve collision sizes and origin
   points. Gameplay scripts should not change during this step.
3. **Production art**: final model/material pass with stable skeletons and named
   animation clips.
4. **Polish**: particles, shader variants, impact frames, camera shake, audio
   sync markers, and accessibility color checks.

## Character and enemy animation contract

Future character scenes should expose these stable animation names so gameplay
code can call one semantic layer instead of individual clips:

| State/action | Clip name | Trigger source |
| --- | --- | --- |
| Idle | `idle` | No movement input |
| Move | `move` | Character velocity above dead zone |
| Jump | `jump_start` | Jump input accepted |
| Land | `land` | Floor contact after airtime |
| Basic hit | `basic_hit` | `Player.hit_performed` |
| Verb activate | `verb_activate_<verb_name>` | `Player.verb_activated` |
| Damage | `damage` | Health reduced |
| Death | `death` | `Player.died` or `SwarmMonster.monster_died` |

Bridge this through an `AnimationPlayer` or `AnimationTree` child under each
actor scene. Keep collision shapes authored in Godot and preserve the current
root-node types (`CharacterBody3D`, `Area3D`, `Node3D`) so code keeps working.

## Import settings

- Export animated 3D assets as `.glb` from Blender using meter scale and +Y up
  conventions compatible with Godot's importer.
- Apply transforms before export; actor feet or base contact should sit at the
  scene origin.
- Put armatures and meshes under a single named root per asset.
- Keep collision separate from render meshes; gameplay collision remains in
  `.tscn` files unless a prop needs authored static collision.
- Use shared materials for verb readability: burn, shield, grow, stretch, roll,
  jump, bounce, freeze, and rewind should each have a consistent color/VFX key.

## Review checklist

- The graybox scene still runs if the imported mesh is temporarily hidden.
- Mesh origin, scale, and facing direction match the old primitive placeholder.
- Animation clip names match the contract table exactly.
- No gameplay script depends on a mesh node path deeper than the actor's visual
  adapter node.
- Materials pass a colorblind/readability check against floor and enemy colors.
- Exported files are committed; heavyweight editable source files can be tracked
  with Git LFS if they become large.
