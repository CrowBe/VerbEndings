# Material Dispenser Modelling Comparison

## Purpose

This is a bounded proxy-asset comparison between procedural modelling through Blender MCP and Meshy 6 multi-image-to-3D. It does not replace the runtime greybox or choose a production asset. Both lanes use the same approved references and are evaluated under the same Blender and Godot conditions.

## Canonical Function

The asset is the Semantic Engine's Material Dispenser: facility machinery that dispenses Material during an Experiment and stops while the Semantic Engine is offline during the Collapse. It is machinery, not an Engine avatar or conversational persona.

Repository sources:

- `CONTEXT.md`: Material is dispensed by the Semantic Engine as an environmental supply.
- `docs/WORLD_DESIGN.md`: the facility is clinical, buoyant, tactile, overconfident and quietly uncanny; production art uses rounded simplified stylised-PBR forms with believable mass.
- `scenes/MaterialDispenser.tscn`: the greybox body is a 1.6 m diameter, 2.0 m high cylinder with a floor-contact origin; `DispenseSocket` is at Godot position `(0, 0.4, 1.1)`.
- `scripts/MaterialDispenser.gd`: gameplay owns timing, Collapse gating and Material creation.

## Shared Design Brief

Create one freestanding industrial dispenser with:

- a squat cylindrical primary body, 1.6 m diameter and 2.0 m high;
- floor contact at the asset origin;
- a clearly readable front dispensing nozzle/aperture, centred 0.4 m above the floor and extending to approximately 1.1 m from the root;
- a stable weighted base, rounded protective shell panels, a charcoal mechanical recess and a thick nozzle collar;
- one systems-cyan illuminated status ring plus a physical shutter/iris cue, so state is not communicated by colour alone;
- large tactile relationships rather than tiny switches, labels or precision controls;
- no text, logos, face, eyes, mouth, screen persona, loose hoses or exposed fragile parts;
- neutral facility materials: equipment grey `#66727A`, charcoal `#273238`, warm off-white `#F1EEE6`, systems cyan `#56D6D2`, and soft-white emission only where needed.

The silhouette must remain recognisable from the third-person gameplay camera and read as a machine that physically dispenses a soft substrate.

## Coordinate And Runtime Contract

- Blender: Z-up, front faces negative Y, floor contact at Z = 0.
- Godot: Y-up after GLB import, with the front aligned to the runtime scene's dispensing direction.
- One predictable root named `material_dispenser`.
- Applied transforms and metre scale.
- The imported visual remains separate from Godot-owned collision and `DispenseSocket` gameplay placement.
- Runtime candidate format: GLB.
- Editable Blender source retained for the Blender lane and for the shared evaluation scene.

## Geometry Budget

- Static prop; no rig or animation clips.
- Target approximately 5,000 triangles; hard ceiling 12,000 triangles after normalisation.
- No non-manifold edges, degenerate faces, inverted normals or unintended disconnected debris.
- Separate named material slots are acceptable; gameplay must not depend on imported descendants.

## Controlled Lanes

### Blender MCP

Build from primitives and modifiers against the dimensional contract. Use separate logical components for base, body shell, panel bands, recess, nozzle, shutter cue and status ring. Save an editable `.blend`, export GLB and produce a neutral evaluation render.

### Meshy 6

Use the approved multi-view reference crops. Generate a standard untextured model with triangle topology, approximately 5,000 polygons, no PBR or texture generation, GLB only, bottom origin and multi-view thumbnails. Record the task identifier and exact parameters. Do not manually improve its geometry before the first evaluation capture.

## Evaluation Matrix

Score each lane from 1–5 and retain objective measurements where available:

1. Canon and visual-language fit.
2. Silhouette and nozzle readability from gameplay distance.
3. Body-envelope and socket-position accuracy.
4. Topology health, triangle count and disconnected components.
5. Origin, scale, transforms, naming and material separability.
6. Editability and ease of authored state variants.
7. Time to first valid GLB and manual intervention required.
8. Godot 4.3 import, parse and representative-scene behaviour.

Both models are rendered with identical camera, lighting, floor and shared materials. Meshy receives no credit for generated textures because the first comparison isolates geometry and structure.

## Retained Artefacts

- Approved reference sheet and crops: `docs/art/material_dispenser_comparison/references/`
- Blender and Meshy evidence renders: `docs/art/material_dispenser_comparison/`
- Evaluation: `docs/art/material_dispenser_comparison/EVALUATION.md`
- Provenance: `docs/art/material_dispenser_comparison/PROVENANCE.md`
- Retained Meshy concept source: `assets/source/props/material_dispenser/material_dispenser_meshy6_concept.glb`
- Retained Blender source: `assets/source/props/material_dispenser/material_dispenser_blender_mcp.blend`
- Cleaned Blender proxy export: `assets/exports/props/material_dispenser_blender_mcp.glb`

Large intermediate and rejected binaries are not retained. No gameplay scene references the comparison export.