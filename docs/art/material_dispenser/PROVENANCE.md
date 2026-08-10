# Material Dispenser Production Provenance

## Role

The Material Dispenser is Semantic Engine facility machinery supplying Material during non-combat Experiments. The imported GLB owns presentation only; `scenes/MaterialDispenser.tscn` retains its script, Godot collision, and Dispense Socket.

This asset advances issue #46 without implementing the complete Sustained Exposure Protocol.

## References

- Approved turnaround: `docs/art/material_dispenser_comparison/references/turnaround_approved.png`
- Approved crops: `front.png`, `left_side.png`, `back.png`, and `front_three_quarter.png` beside the turnaround
- High-detail shape source: `assets/source/props/material_dispenser/material_dispenser_meshy6_concept.glb`
- Comparison evidence: `docs/art/material_dispenser_comparison/EVALUATION.md`
- Production brief: `docs/art/material_dispenser/BRIEF.md`

The retained Meshy concept came from task `019fe996-95a7-7333-bf21-063c50212a4a` using Meshy 6 multi-image reconstruction. No new Meshy task or generation credits were used for the production reconstruction.

## Blender Reconstruction

- Blender: 5.2.0 LTS
- Hermes MCP server: `blender-mcp==1.6.4` with `mcp[cli]<2`
- Compatible add-on source: `MCPBlender/blender-mcp` commit `2f973e9517c000527f7e570389fcf44285cc656f`
- Implementation model: DeepSeek V4 Flash through Nous Portal
- Method: reference-driven procedural hard-surface reconstruction through scoped Blender MCP operations
- Dense reference handling: imported only for visual inspection and removed before final source save/export

## Retained Outputs

- Editable source: `assets/source/props/material_dispenser/material_dispenser.blend`
- Runtime export: `assets/exports/props/material_dispenser.glb`
- Build evidence: `docs/art/material_dispenser/BUILD_EVIDENCE.json`
- Four-view renders: `docs/art/material_dispenser/renders/`

Exact sizes, hashes, object names, materials, bounds, and topology evidence are stored in `BUILD_EVIDENCE.json` and verified again from the exported GLB before integration.

## Engine Boundary

Godot 4.3 imports the asset beneath `MaterialDispenser.tscn` as `Visual`. The scene retains its `Apparatus` static body, cylinder collision, script, and `DispenseSocket` at `Vector3(0, 0.4, 1.1)`. The imported GLB contains no collision, script, camera, light, floor, rig, or animation.

## Validation

Validation evidence is recorded by the focused Material Dispenser suite and the canonical commands in `docs/VALIDATION.md`. Visual acceptance uses the four retained material renders and representative in-engine presentation.

## Current Limitation

The asset establishes the visual and engine boundary only. Issue #46 still owns the Applied Attrition Protocol conversion, atmospheric Stability Loss, risky dispenser placement, breakable Material housings, per-Verb routes, and scoring changes.
