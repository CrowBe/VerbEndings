# Visual Asset And Animation Pipeline

## Asset Boundary

Gameplay scenes own root node types, collision, signals, and behaviour. Imported assets provide presentation behind those interfaces. Replacing a primitive or proxy does not require changes to gameplay logic.

The repository currently contains primitive Godot meshes and procedural tweens. Production assets use this layout:

```text
assets/
  source/              # Editable Blender, Krita, or Aseprite files
  exports/
    subjects/          # Runtime GLB and texture exports
    residuals/
    props/
    vfx/
  materials/           # Shared Godot material resources
  animation/           # Shared AnimationLibrary resources
docs/art/               # Art bible, briefs, contact sheets, naming references
```

Use lowercase snake_case filenames and matching concept names between source and export files. Runtime scenes reference exported files, never source files.

[`docs/art/README.md`](art/README.md) indexes the approved identity, spatial, and intro-staging references. These images constrain shape, proportion, material, palette, and composition; they are not runtime assets and do not imply that production art is implemented.

## Asset Readiness

An asset has one of four readiness levels:

1. **Greybox** — primitive geometry validates scale, collision, and gameplay.
2. **Proxy** — exported geometry preserves the approved dimensions, origin, and collision envelope.
3. **Production** — final geometry, materials, skeleton, and required animation clips use stable interfaces.
4. **Polish** — VFX, impact frames, camera response, audio markers, and accessibility checks are integrated.

## Animation Contract

Subject and Residual scenes expose semantic animation names through an `AnimationPlayer` or `AnimationTree` adapter:

| State or action | Clip name | Gameplay trigger |
| --- | --- | --- |
| Idle | `idle` | Movement below the dead zone |
| Move | `move` | Movement above the dead zone |
| Jump | `jump_start` | Accepted jump input |
| Land | `land` | Floor contact after airtime |
| Basic Impact | `basic_hit` | Accepted basic-hit presentation request |
| Verb Expression | `verb_expression_<verb_name>` | Verb-Expression signal |
| Stability Loss | `stability_loss` | Stability decreases |
| Destabilisation | `destabilise` | Stability reaches zero from an Impact |

The adapter translates literal gameplay-code signals into this semantic contract. Gameplay code does not address skeleton bones or imported mesh descendants directly.

The production `basic_hit` clip may contain one call-method track key at its authored contact frame. The track targets the actor's `AnimationAdapter` relative to the `AnimationPlayer` root and calls `basic_hit_contact()` with no arguments. The adapter emits the gameplay `basic_hit_impact` signal at most once for that accepted presentation attempt. If the clip has no marker, the adapter emits the signal at the end of the clip duration. The proxy fallback emits at the fist's full extension after anticipation. Imported visual or animation descendants never call gameplay code or emit gameplay signals.

## Import Contract

- Export animated 3D assets as GLB at metre scale with transforms applied.
- Place an actor's feet or a prop's contact surface at the scene origin.
- Use one predictably named root per exported asset.
- Keep collision in `.tscn` scenes except for intentionally authored static prop collision.
- Use shared materials for facility surfaces and consistent per-Verb readability.
- Keep the shared Subject mesh independent of its claimed Verb. Apply the per-Verb substrate tone and the smaller Verb line beneath the `SAD` badge through runtime material or decal variants.
- Track large editable source files with Git LFS when ordinary Git becomes impractical.

## Acceptance Checks

### Generative reference safety

- Describe the project's rendering language through visual properties such as rounded forms, tactile materials, controlled industrial lighting, and stylised proportions. Do not use third-party studio, franchise, artist, or brand names as style shorthand.
- Identify supplied inputs as original project-owned fictional designs when submitting them to external generation services.
- Use clean single-frame compositions for video keyframes. Multi-panel turnarounds and design sheets remain identity references, not literal video frames.
- Describe contained Residuals as inactive jelly predecessors and state their bloodless, non-aggressive presentation explicitly. Do not rely on ambiguous experimentation, injury, or horror terminology in generation prompts.
- Exclude third-party characters, logos, brands, graphic violence, gore, weapons, and unrequested on-screen text explicitly.
- Prompt simplification must not alter canonical product terminology in repository documentation or runtime presentation.

An asset is acceptable only when:
- Hiding the imported visual leaves gameplay collision and logic functional.
- Origin, scale, facing direction, and collision envelope match the approved greybox.
- Required animation names exist and trigger through the adapter.
- No gameplay script depends on an imported node path.
- Silhouette and motion communicate state without relying on colour alone.
- Materials remain readable against each Laboratory floor and hostile presentation.
- Exported runtime assets are committed alongside any required import metadata.
