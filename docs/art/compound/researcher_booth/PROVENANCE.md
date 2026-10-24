# researcher_booth — Meshy provenance

Evidence class: **Production Source (concept) — not runtime.** Requires tidy/retopo before any export.

- Service: Meshy (multi-image-to-3d), model `meshy-6`
- Task ID: `01a17011-c644-718c-8a6b-cb5da7c0e96c` — status SUCCEEDED
- Created/finished (UTC): 2026-10-24T22:39:36.483000+00:00 / 2026-10-24T22:45:05.058000+00:00
- Credits: before 980, after 950, consumed 30 (approved cap 30; Benjamin OK t47s223)
- Settings: should_texture=true, enable_pbr=true, hd_texture/texture_resolution=4k, should_remesh=false, remove_lighting=true, target_formats=[glb], no pose_mode
- Output: `assets/source/compound/researcher_booth/researcher_booth_meshy6_concept.glb` — 78981568 B, sha256 `9022d77c88a007086e0c2dbaae8e03f1058c744736277d49e00151657a5c233e`

## Inputs (in submission order, from sheet-batch-2 crops b7d4b31)
- `docs/art/compound/researcher_booth/meshy_inputs/front.png` — 110134 B, sha256 `c194835cfce86fedc199df1b5a2f5a225bd652a9e053bc4810aff5867e482532`
- `docs/art/compound/researcher_booth/meshy_inputs/three_quarter.png` — 117803 B, sha256 `c9b4d34fa559657b4ebb5b95df0ddc0663d2b74b6b7a10fd5c75f3527ce1c03b`
- `docs/art/compound/researcher_booth/meshy_inputs/side.png` — 77971 B, sha256 `68a3b35fcddcd8f791ec5bfcc394134d54e3b5b7ce35cbd46990433fdfc95912`
- `docs/art/compound/researcher_booth/meshy_inputs/back.png` — 81345 B, sha256 `3e0dd1b57002a8d9cde36a7a274ea2fad9e09659af99301bf0d5bb69ce973a09`

Evidence: `BUILD_EVIDENCE_meshy6.json`

## Structural inspect (Blender 5.2.0 LTS)

- triangles: 1,955,282
- vertices: 1,060,442
- dimensions (m): 1.899 × 1.899 × 1.604
- non_manifold_edges (welded): 0
- welded connected components: 2
- materials: Material_0
- Evidence: `INSPECT_meshy6.json`

Concept only. High poly (~2.0M tris) — retopo before runtime. Origin not floor-snapped (floor_offset −0.80).
