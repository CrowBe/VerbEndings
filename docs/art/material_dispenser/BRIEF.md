# Production Material Dispenser Brief

## Issue Relationship

This asset slice advances `CrowBe/VerbEndings#46` by replacing the Applied Attrition Material Dispenser's primitive visual with a production-preparation asset while preserving the existing apparatus script, Dispense Socket, and Godot-owned collision. It does not implement the complete Sustained Exposure Protocol and does not close issue #46.

## Canon And Role

The Material Dispenser is physical Semantic Engine machinery. It supplies Material during non-combat Experiments and stops when the Semantic Engine is offline during the Collapse. It has no face, avatar, conversational persona, text, or autonomous character cues.

The visual style is stylised PBR: rounded simplified forms, believable mass, a neutral facility body, systems cyan for normal infrastructure state, and a dark empty aperture. Capitalised Material is the substrate gameplay resource; lower-case material refers only to rendering surfaces.

## Approved Sources

- `docs/art/material_dispenser_comparison/references/turnaround_approved.png`
- the four approved reconstruction crops beside it
- `assets/source/props/material_dispenser/material_dispenser_meshy6_concept.glb` as a high-detail shape reference only
- the controlled comparison and retained Blender proxy as measured evidence, not as mandatory geometry

No new Meshy generation or credits are required.

## Visual Acceptance

- Squat 1.6 m-wide, 2.0 m-high cylindrical machine with an obviously weighted faceted base and a shallow layered top cap.
- The body, base, and top cap read as one manufactured assembly rather than stacked unrelated primitives.
- Warm off-white protective panels follow the cylinder and sit inside equipment-grey/charcoal framing; no floating shards or arbitrary fins.
- A continuous front chassis links the upper vent/status area to an integrated aperture assembly.
- The aperture is centred 0.4 m above the floor, reaches approximately 1.1 m forward from the origin, and remains subordinate to the body rather than reading as a separate valve.
- The aperture has a dark recessed centre, a mechanical shutter/iris cue, a segmented systems-cyan status ring, and small soft-white status elements. It must not resemble eyes or a mouth.
- Rear vent treatment remains distinct from the front dispensing aperture.
- The silhouette, panel hierarchy, aperture, and base remain legible from front, side, back, and front three-quarter views.

## Structural Acceptance

- Blender Z-up; front is negative Y; floor contact at Z = 0.
- Root Empty named `material_dispenser` at identity transform.
- Asset dimensions: 1.6 m wide, 2.0 m high, and no more than approximately 1.9 m deep including the aperture.
- Applied mesh transforms, stable semantic object names, and five or fewer facility material slots.
- Separate components for weighted base, shell, protective panels, recess/vent, aperture collar, shutter, and status elements.
- Target 8,000–12,000 triangles; hard ceiling 15,000.
- Zero degenerate polygons and zero non-manifold edges after positional welding.
- No rigging, animation, cameras, lights, reference mesh, or collision in the runtime GLB.
- Editable source: `assets/source/props/material_dispenser/material_dispenser.blend`.
- Runtime export: `assets/exports/props/material_dispenser.glb`.

## Integration Acceptance

- `scenes/MaterialDispenser.tscn` keeps its stable root script, `Apparatus` static body, Godot cylinder collision, and `DispenseSocket` at `Vector3(0, 0.4, 1.1)`.
- The primitive `CylinderMesh` is replaced by an imported `Visual` instance; imported descendants own presentation only.
- Hiding the imported visual leaves collision and dispensing behaviour intact.
- The GLB imports and instantiates under Godot 4.3 without errors or warnings.
- A focused headless suite verifies visual presence, dimensions, facing/socket alignment, triangle/material budgets, no imported collision, and hidden-visual gameplay boundaries.

## Required Evidence

- Blender source and runtime GLB hashes.
- Blender inspection JSON.
- Front, side, back, and front three-quarter controlled renders.
- Godot 4.3 import and focused-suite output.
- Provenance naming the approved reference, Meshy concept source, Blender/MCP versions, exact build approach, and any retained limitations.
