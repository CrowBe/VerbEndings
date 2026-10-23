# Shared Subject Source Provenance

## Role

This directory contains the project-owned visual and generated three-dimensional sources for the common Subject body. `GLOSSARY.md`, `docs/WORLD_DESIGN.md`, and `docs/VISUAL_ASSET_PIPELINE.md` remain authoritative wherever generated evidence is ambiguous.

## Prune (2026-10-23)

Benjamin approved removal of the wrong-design Shared Subject concept meshes and related Meshy outputs:

- deleted `assets/source/subjects/shared_subject/shared_subject_meshy6_concept.glb`
- deleted `assets/source/subjects/shared_subject/shared_subject_meshy6b_concept.glb`
- deleted `docs/art/subjects/shared_subject/renders/` and `BUILD_EVIDENCE.json` / `BUILD_EVIDENCE_meshy6b.json`
- removed wiki model symlink / shared_subject_renders symlink; detail page demoted to 2D refs only

**Retained:** `references/` turnarounds and `meshy_inputs/` crops (direction for a future run). Generation records below are audit history only — the GLB files are gone.

## Reference Lineage

The SHIELD, GROW, BOUNCE, and group-dispensing sheets were authored for VerbEndings intro and visual-development work. They establish one common mouthless droplet anatomy and garment construction. The exact retained files are:

| Path | Purpose | SHA-256 |
| --- | --- | --- |
| `references/subject_shield_turnaround.png` | Primary anatomy and surface reference | `60865b5276049e0593145c6d442e1b054e352199bf7991e88b73b289c24325d6` |
| `references/subject_grow_turnaround.png` | Cross-sheet geometry consistency | `c94fb5ef9d1a410b8a128e27d057e855eb5ec75f14279264fd6a2ddb0d3cef6d` |
| `references/subject_bounce_turnaround.png` | Cross-sheet geometry consistency | `28a6ef334b9bdd7ae7126940eef70498510f025e7af484d88141970e2a14cb2a` |
| `references/subject_group_dispense_reference.png` | Group performance and approximate scale | `b9bfffed68c94ac1c8fb65e8858abd6089a0d2fffe304e8e9c28a9f369b03dc2` |

## Meshy Inputs

The four inputs are deterministic, unretouched crops of the SHIELD turnaround. Cropping removes neighbouring views while retaining complete silhouette and floor contact.

| Path | View | SHA-256 |
| --- | --- | --- |
| `meshy_inputs/subject_shield_front.png` | Front | `2de29cc184f8e0511d59a7978a22fd028948a3bcfaef4834e27be76c49a8cb3b` |
| `meshy_inputs/subject_shield_front_three_quarter.png` | Front three-quarter | `c4e550b0c25060b5e90fac7dc6561705c6d033d98b6eb73292abefca28454083` |
| `meshy_inputs/subject_shield_side.png` | Side | `fbb17d9c84074137cf87107e03573d0c2aa3080377e59bff30809a3f7a17341f` |
| `meshy_inputs/subject_shield_back.png` | Back | `5502f979895a99166cd510f7a8ea8540322f86e559a7638d336a9cc259638020` |

## Generation Record

- Service: Meshy multi-image-to-3D.
- Model: Meshy 6.
- Task identifier: `019ff59e-649d-7005-b011-169bebc58f30`.
- Result: succeeded.
- Credits: `2231` before, `2201` after, `30` consumed.
- Inputs: front, front three-quarter, side, and back crops listed above.
- Model type: standard.
- Pose request: T-pose. The generated squat neutral stance is not a production rig pose.
- Texturing: PBR and HD texture enabled, baked-light removal enabled.
- Image enhancement, alpha thumbnail, and multi-view thumbnails: enabled.
- Remesh: disabled so the high-resolution source remains intact.
- Format: self-contained GLB.
- No rigging, animation, retexture, resize, conversion, or additional generation is applied.

The (now pruned) source was `assets/source/subjects/shared_subject/shared_subject_meshy6_concept.glb`, `28,025,972` bytes, SHA-256 `215880e66b5bd76a528565cc1eff37b3d37d5dfbf0a82db7e706263972c7a6e7`. Four texture images are embedded in the GLB; redundant extracted copies are not retained.

## Inspection And Disposition

Blender 5.2.0 LTS inspection records one mesh and one material with `145,482` vertices and `271,798` triangles. Raw bounds are approximately `1.333 × 1.091 × 1.899 m`, centred around the source origin. Positional-weld inspection records one connected shell, zero non-manifold edges, and zero degenerate polygons. The GLB contains no skin, animation, camera, collision, or gameplay data.

Controlled `1.2 m`-high renders establish model negative Y as front and model positive Y as back. This mesh was later pruned as wrong design. Evidence files were removed with it.

The Blender inspection and rendering environment used its nonfatal OpenColorIO fallback because the packaged configuration was newer than the linked library. Both operations completed and their output evidence validated.

## Generation Record (pipeline handoff re-run — meshy6b)

Live Meshy Desk pipeline test (Benjamin OK on Shared Subject re-run, ~30 credits). Both concept GLBs later pruned (wrong design).

- Service: Meshy multi-image-to-3D.
- Model: Meshy 6 (`meshy-6`).
- Task identifier: `01a16653-6775-7468-8025-365233db76a3`.
- Result: succeeded.
- Credits: `1100` before, `1070` after, `30` consumed.
- Inputs: same four `meshy_inputs/` crops (SHA-256 unchanged; listed above).
- Model type: standard.
- Pose request: T-pose.
- Texturing: PBR and HD texture enabled, baked-light removal enabled.
- Image enhancement, alpha thumbnail, and multi-view thumbnails: enabled.
- Remesh: disabled so the high-resolution source remains intact.
- Format: self-contained GLB.
- No rigging, animation, retexture, resize, conversion, or additional generation is applied.

The (now pruned) source was `assets/source/subjects/shared_subject/shared_subject_meshy6b_concept.glb`, `31,361,764` bytes, SHA-256 `9bc0e67c533ae22d6d862ca6d9b2687cd800f758f0f75dfc8a6aa0642c983922`.

### Inspection (meshy6b)

Blender 5.2.0 LTS inspection records one mesh and one material with `161,604` vertices and `298,732` triangles. Raw bounds are approximately `1.349 × 1.130 × 1.899 m`, centred around the source origin. Zero non-manifold edges after positional weld; two welded connected components. Machine-readable evidence: `BUILD_EVIDENCE_meshy6b.json`.

This file was later pruned as wrong design. Do not retopo from it. Evidence files were removed with it.
