# Material Dispenser Comparison Provenance

## Repository Baseline

- Repository: `CrowBe/VerbEndings`
- Base branch: `origin/main`
- Base commit: `45707d6c46ef4942f654f3553960000b05324d61`
- Working branch: `experiment/material-dispenser-comparison`
- Godot target: 4.3
- Blender: 5.2.0 LTS

## Shared Reference

- Renderer: OpenAI Codex `gpt-image-2-high`.
- Initial text-to-image draft: not retained because the generated substrate protruded from the aperture and would have biased reconstruction towards fused geometry.
- Rejected draft SHA-256: `904d1ab8bffdcd1060e7256a62d3e77299efccb2e8d63f3b678d21c872e5912b`.
- Approved image-edit output: `references/turnaround_approved.png`.
- Approved SHA-256: `4dee149089d21171e25b5b29abfa5f54b1d64830f0b7891dd0b1a2a0e42a4541`.
- Approved crops: `front.png`, `left_side.png`, `back.png`, and `front_three_quarter.png` (624 × 624 pixels each).
- Visual review: passed. All four crops contain one consistent idle machine, an empty shuttered aperture, no substrate, no text, no extra object, and no grid-line contamination.

### Initial Reference Prompt

> A production-ready multi-view turnaround reference sheet for ONE identical stylised hard-surface game prop: the VerbEndings Semantic Engine Material Dispenser. Four clean separated views in a precise 2x2 grid: FRONT orthographic, LEFT SIDE orthographic, BACK orthographic, and FRONT THREE-QUARTER. The exact same object and proportions in every view. No text, no labels, no arrows, no logos, no people, no extra objects. Design: squat freestanding cylindrical industrial dispenser, body exactly about 1.6 metres diameter and 2.0 metres high. Broad weighted base touching the floor, rounded simplified protective shell panels, believable heavy mass, thick equipment-grey machinery, warm off-white panel inserts, charcoal recessed mechanisms. At the lower front, a large unmistakable physical dispensing nozzle/aperture centred about 0.4 metres above the floor, projecting forward from a thick collar; it dispenses a soft jelly-like substrate. Around the aperture is a chunky mechanical iris/shutter cue and a systems-cyan illuminated status ring. Large tactile shapes only, no tiny controls, no exposed wires, no fragile hoses. The machine must not resemble a face, robot, creature, or conversational avatar. Visual direction: clinical, buoyant, tactile, overconfident, quietly uncanny; rounded simplified stylised PBR with believable rough metal, painted composite panels, mass and contact. Facility palette only: equipment grey #66727A, charcoal #273238, warm off-white #F1EEE6, systems cyan #56D6D2, tiny soft-white emission. Neutral light-grey seamless background, even studio lighting, minimal soft contact shadow, no perspective distortion in orthographic views. Geometry and panel seams must be consistent across all four views. Crisp high-resolution concept/model sheet suitable as shared input for both procedural Blender modelling and multi-image 3D reconstruction.

### Corrective Image-Edit Prompt

> Edit this exact four-view turnaround sheet while preserving the machine's geometry, camera views, panel layout, proportions, colours, lighting, clean 2x2 grid and consistency. Remove every visible piece of pale cyan jelly/substrate protruding from the dispensing opening in the front, side and three-quarter views. The dispenser itself must be empty and idle: replace the jelly with a clean dark recessed circular aperture inside the existing thick mechanical collar and segmented iris/shutter. Keep the systems-cyan illuminated ring around the opening, but put no cyan object inside it. Do not add text, labels, logos, controls, eyes, a mouth, a face or extra objects. Make the circular aperture and iris geometry consistent in all views where visible. Return the same crisp high-resolution neutral-background production turnaround sheet.

## Blender MCP Lane

- Hermes MCP server: `blender-mcp==1.6.4`.
- MCP Python SDK constraint: `mcp[cli]<2`.
- Blender add-on source commit: `2f973e9517c000527f7e570389fcf44285cc656f`.
- Telemetry: disabled.
- Enabled tools: scene info, object info, viewport screenshot, and Blender code execution.
- Modelling route: procedural `bpy` primitives and applied modifiers in Blender 5.2.0 LTS; no generative 3D service used.
- Editable source: `assets/source/props/material_dispenser/material_dispenser_blender_mcp.blend`, 260,690 bytes, SHA-256 `36bf82b96ddebac69673d9ef218b8515b7c24c733faeced451a32a5282603a22`.
- Evidence render: `blender_mcp/material_dispenser_blender_mcp_raw.png` (768 × 768).
- Measured build evidence: `blender_mcp/build_evidence.json`.
- Raw authored result: 49 meshes, 5,724 triangles, zero non-manifold edges after positional welding, identity `material_dispenser` root, 1.6 m lateral envelope, 2.0 m height, and front extent at approximately Y = -1.1 m.
- Cleanup evidence: `blender_mcp/cleanup_evidence.json`; 360 tiny or degenerate triangles removed and face normals recalculated.
- Retained proxy export: `assets/exports/props/material_dispenser_blender_mcp.glb`, 315,016 bytes, 5,364 triangles, SHA-256 `510a828b0c7fbfae94202432518c1cc498ea06c91a08a34d3b21119855cb8c8b`.
- Retained Godot import settings disable generated LODs for this 5,364-triangle proxy. The default LOD pass produced a non-finite-normal warning; import is warning-free with the unnecessary generated-LOD pass disabled.

## Meshy Lane

- Route: multi-image-to-3D from the four approved reference crops.
- Selected model: Meshy 6.
- Task ID: `019fe996-95a7-7333-bf21-063c50212a4a`.
- Result: succeeded after 130 seconds and eight status polls.
- Credits: 2,335 before, 20 consumed, 2,315 after.
- Exact generation parameters:
  - `model_type`: `standard`
  - `topology`: `triangle`
  - `target_polycount`: `5000`
  - `should_remesh`: `true`
  - `save_pre_remeshed_model`: `true`
  - `should_texture`: `false`
  - `enable_pbr`: `false`
  - `image_enhancement`: `true`
  - `auto_size`: `true`
  - `origin_at`: `bottom`
  - `target_formats`: `glb`
  - `multi_view_thumbnails`: `true`
  - `alpha_thumbnail`: `true`
- Automatic remesh result: 227,912 bytes, 5,000 triangles, 162 non-manifold edges after positional welding, and no retained production value. The binary is not retained; `meshy_6/remeshed_evidence.json` and evaluation renders preserve its evidence.
- Retained pre-remesh concept: `assets/source/props/material_dispenser/material_dispenser_meshy6_concept.glb`, 22,516,688 bytes, 1,250,962 triangles, SHA-256 `dc8a00d8b6b66baabd61dc55835e08c79accd3a710260e4d848636d54ee7da1a`.
- Pre-remesh inspection evidence: `meshy_6/pre_remeshed_evidence.json`.
- No manual geometry improvement was applied before the controlled captures.

## Validation

- `blender --background --python tools/asset_pipeline/inspect_glb.py -- assets/exports/props/material_dispenser_blender_mcp.glb …`: 5,364 triangles, zero non-manifold edges after positional welding, and dimensions 1.600 × 1.898 × 2.000 m.
- `blender --background --python tools/asset_pipeline/clean_glb.py -- …`: idempotent against the retained proxy; zero additional triangles removed.
- `blender --background --python tools/asset_pipeline/normalise_and_render_glb.py -- …`: completed four controlled clay renders without changing scale or floor offset.
- `python3 tools/validate_project.py`: passed.
- Godot `4.3.stable.official.77dcf97d8` import check: passed with no warnings under the retained import settings.
- Retained asset instantiation check: passed with 49 mesh instances, 5,364 triangles, five expected materials, 1.6 m width, 2.0 m height, floor offset zero, and no imported collision.
- Eight-second Godot headless runtime smoke: reached the expected timeout exit status 124 with no engine or script errors.

## Retained State

The high-detail Meshy result is retained as a source concept, and the editable Blender source plus cleaned GLB are retained as the proxy implementation. Rejected and duplicate binaries were removed. No gameplay scene references the proxy export.