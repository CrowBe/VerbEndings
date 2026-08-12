# Shared Subject Pilot Provenance

## Role

This directory contains project-owned reference evidence and Meshy pilot inputs for a shared Subject body advancing issue #24. `CONTEXT.md`, `docs/WORLD_DESIGN.md`, and `docs/VISUAL_ASSET_PIPELINE.md` on the branch remain authoritative wherever an older visual sheet is ambiguous.

## Reference source

The reference sheets were authored for the project video/intro work and are recoverable from repository commit:

```text
fb98588ffa4c841ca26338333b1139046941d770
feat: track visual references and placeholder intro
```

That commit currently remains reachable from `origin/docs/compound-visual-reference`; it is not an ancestor of current `main`. This feature branch retains only the Subject sheets needed for the pilot rather than importing the older branch's documentation or gameplay assumptions.

## Retained project-owned references

| Path | Purpose | SHA-256 |
| --- | --- | --- |
| `references/subject_shield_turnaround.png` | Primary shared-anatomy and SHIELD material reference | `60865b5276049e0593145c6d442e1b054e352199bf7991e88b73b289c24325d6` |
| `references/subject_grow_turnaround.png` | Shared-geometry consistency and green substrate reference | `c94fb5ef9d1a410b8a128e27d057e855eb5ec75f14279264fd6a2ddb0d3cef6d` |
| `references/subject_bounce_turnaround.png` | Shared-geometry consistency and pink substrate reference | `28a6ef334b9bdd7ae7126940eef70498510f025e7af484d88141970e2a14cb2a` |
| `references/subject_group_dispense_reference.png` | Mouthless group performance and scale consistency | `b9bfffed68c94ac1c8fb65e8858abd6089a0d2fffe304e8e9c28a9f369b03dc2` |

## Meshy input preparation

The four Meshy input files are deterministic, unretouched crops of the SHIELD turnaround. No pixels were generated or repainted. Cropping removes neighbouring views while retaining complete silhouette and floor contact.

| Path | View | SHA-256 |
| --- | --- | --- |
| `meshy_inputs/subject_shield_front.png` | front | `2de29cc184f8e0511d59a7978a22fd028948a3bcfaef4834e27be76c49a8cb3b` |
| `meshy_inputs/subject_shield_front_three_quarter.png` | front three-quarter | `c4e550b0c25060b5e90fac7dc6561705c6d033d98b6eb73292abefca28454083` |
| `meshy_inputs/subject_shield_side.png` | side | `fbb17d9c84074137cf87107e03573d0c2aa3080377e59bff30809a3f7a17341f` |
| `meshy_inputs/subject_shield_back.png` | back | `5502f979895a99166cd510f7a8ea8540322f86e559a7638d336a9cc259638020` |

## Generation record

- Generation tool: Meshy multi-image-to-3D.
- Model: `meshy-6`.
- Task identifier: `019ff59e-649d-7005-b011-169bebc58f30`.
- Result: `SUCCEEDED`.
- Credit balance: `2231` before and `2201` after; Meshy reported `30` credits consumed.
- Inputs: the four unretouched SHIELD crops listed above, ordered front, front three-quarter, side, back.
- Model type: standard.
- Pose mode: T-pose request; the returned squat neutral stance preserves the source identity but is not a production rig pose.
- Texturing: enabled with PBR, HD texture, image enhancement, alpha thumbnail, multi-view thumbnails, and baked-light removal.
- Remesh: disabled so the raw high-resolution concept remains available as shape evidence.
- Requested and downloaded format: self-contained GLB only.
- No rigging, animation, retexture, resize, conversion, or additional Meshy generation was used.

The downloaded concept is:

```text
assets/source/subjects/shared_subject/shared_subject_meshy6_concept.glb
```

- Size: `28,025,972` bytes.
- SHA-256: `215880e66b5bd76a528565cc1eff37b3d37d5dfbf0a82db7e706263972c7a6e7`.
- The download tool also extracted convenience copies of the embedded texture maps. Those redundant copies were removed after their hashes were captured because the GLB remains self-contained.
- Temporary source URLs are intentionally omitted because they expire.

## Inspection and disposition

Blender 5.2.0 LTS inspection found one mesh and one material with `145,482` vertices and `271,798` triangles. The raw bounds are approximately `1.333 × 1.091 × 1.899 m`, centred around its source origin rather than placed on `Z=0`. Positional-weld inspection found one connected shell, zero non-manifold edges, and zero degenerate polygons. The GLB contains no skin, animation, camera, collision, or gameplay data.

Controlled `1.2 m`-high evidence renders establish model negative Y as front and model positive Y as back. The concept preserves the curved droplet peak, two eyes, mouthless face, short arms, broad feet, open jacket, pockets, and back garment panel. It therefore **passes as concept evidence**.

It **fails direct runtime and rigging acceptance** because it is a dense single fused mesh with one material, generated badge/barcode details, no independently controllable body/eye/jacket/identity surfaces, no skin, no animation, incorrect source scale, and no floor-contact origin. Blender must reconstruct or deliberately retopologise the approved form, remove baked Verb-specific markings, establish semantic material boundaries, then validate the rig and deformation before Godot integration.

`BUILD_EVIDENCE.json` is the machine-readable generation, hash, topology, render, and disposition record. The Blender OpenColorIO fallback was nonfatal: both inspection and controlled rendering exited zero and produced validated outputs.
