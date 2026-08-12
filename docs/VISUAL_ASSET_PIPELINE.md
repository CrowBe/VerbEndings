# Visual Asset And Animation Pipeline

## Asset Boundary

Gameplay scenes own root node types, collision, signals, and behaviour. Imported assets provide presentation behind those interfaces. Replacing a primitive or proxy does not require changes to gameplay logic.

The repository contains primitive Godot meshes and procedural tweens alongside an imported production-preparation Material Dispenser prop behind a Godot-owned gameplay boundary. Production assets use this layout:

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

## Asset Readiness

An asset has one of four readiness levels:

1. **Greybox** — primitive geometry validates scale, collision, and gameplay.
2. **Proxy** — exported geometry preserves the approved dimensions, origin, and collision envelope.
3. **Production** — final geometry, materials, skeleton, and required animation clips use stable interfaces.
4. **Polish** — VFX, impact frames, camera response, audio markers, and accessibility checks are integrated.

## Hybrid Concept-To-Production Route

For visually specific 3D props, high-detail generation and runtime modelling are separate asset stages:

1. Write the asset brief first. Fix canon, dimensions, facing, contact origin, polygon budget, material boundaries, collision ownership, and target export before spending generation credits.
2. Approve a consistent turnaround or multi-view reference. Inputs show one object without labels, loose presentation effects, or geometry that should not become part of the asset.
3. Generate a high-detail concept mesh from the approved views and preserve the pre-remesh output under `assets/source/`. It is a shape reference, not a runtime asset.
4. Inspect the concept structurally and visually before any reduction. Record dimensions, origin, triangles, connected components, non-manifold edges, materials, task identifier, model, credits, and exact inputs.
5. For hard-surface props, reconstruct or deliberately retopologise the approved silhouette in Blender rather than trusting an automatic low-poly remesh to preserve panel seams, apertures, and authored state boundaries. Use Meshy geometry directly only when it survives the same structural checks.
6. In Blender, establish the final metre scale and floor-contact origin, separate semantic components and material slots, apply transforms, recalculate normals, remove degenerate geometry, and save the editable `.blend` source.
7. Export only the asset hierarchy to GLB. Cameras, lights, reference planes, and evaluation floors remain outside the export root.
8. Import and instantiate the GLB with Godot 4.3. Gameplay collision, sockets, signals, and scripts remain in `.tscn` scenes. Import settings such as generated LODs are deliberate per asset; warnings are fixed or explicitly avoided only when the asset budget makes that feature unnecessary.

Source-only generator and Blender directories may contain a `.gdignore` so Godot does not import large concept meshes or editable DCC files. Runtime scenes continue to reference only `assets/exports/`.

The repository includes metre-scale Blender helpers for this route:

```bash
blender --background --python tools/asset_pipeline/inspect_glb.py -- \
  input.glb evidence.json

blender --background --python tools/asset_pipeline/normalise_and_render_glb.py -- \
  input.glb evaluation.glb evaluation_renders/

blender --background --python tools/asset_pipeline/clean_glb.py -- \
  input.glb cleaned.glb cleanup_evidence.json
```

`normalise_and_render_glb.py` assigns a shared clay material and is for controlled evaluation, not final material export. At metre scale, `clean_glb.py` collapses faces below 1 mm² and dissolves edges below 0.1 µm; it must run on a retained copy followed by visual, structural, and Godot checks.

The Material Dispenser evidence set in [`docs/art/material_dispenser_comparison/`](art/material_dispenser_comparison/) demonstrates this boundary: the Meshy concept retains visual richness, while the Blender export provides the editable proxy and runtime contract.

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

Alongside the clip names, the adapter owns three presentation services against the same boundary: toggling the whole visual subtree, resolving the actor's facing heading for gameplay, and applying the per-Verb treatment and the Adverb overlay to named child meshes within the visual subtree. A visual asset satisfies the contract by providing those meshes; gameplay code never applies a treatment itself.

The production `basic_hit` clip may contain one call-method track key at its authored contact frame. The track targets the actor's `AnimationAdapter` relative to the `AnimationPlayer` root and calls `basic_hit_contact()` with no arguments. The adapter emits the gameplay `basic_hit_impact` signal at most once for that accepted presentation attempt. If the clip has no marker, the adapter emits the signal at the end of the clip duration. The proxy fallback emits at the fist's full extension after anticipation. Imported visual or animation descendants never call gameplay code or emit gameplay signals.

## Import Contract

- Export animated 3D assets as GLB at metre scale with transforms applied.
- Place an actor's feet or a prop's contact surface at the scene origin.
- Use one predictably named root per exported asset.
- Keep collision in `.tscn` scenes except for intentionally authored static prop collision.
- Use shared materials for facility surfaces and consistent per-Verb readability.
- Track large editable source files with Git LFS when ordinary Git becomes impractical.

## Acceptance Checks

- Hiding the imported visual leaves gameplay collision and logic functional.
- Origin, scale, facing direction, and collision envelope match the approved greybox.
- Required animation names exist and trigger through the adapter.
- No gameplay script depends on an imported node path.
- Silhouette and motion communicate state without relying on colour alone.
- Materials remain readable against each Laboratory floor and hostile presentation.
- Exported runtime assets are committed alongside any required import metadata.
