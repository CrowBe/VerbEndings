# dispensing_line — Meshy provenance

Evidence class: **Production Source (concept) — not runtime.** Requires tidy/retopo before any export.

- Service: Meshy (multi-image-to-3d), model `meshy-6`
- Task ID: `01a19176-913e-731b-bb2c-5ea342f834d2` — status SUCCEEDED
- Created/finished (UTC): 2026-10-31T10:17:11.275000+00:00 / 2026-10-31T10:19:55.906000+00:00
- Credits: before 920, after 890, consumed 30 (approved cap 30; Benjamin OK t34u)
- Settings: should_texture=true, enable_pbr=true, hd_texture/texture_resolution=4k, should_remesh=false, remove_lighting=true, target_formats=[glb], no pose_mode
- Output: `assets/source/compound/dispensing_line/dispensing_line_meshy6_concept.glb` — 29941784 B, sha256 `2ced7534d1ff86ca5ddf3bf6c2303f564b3172e45348ed88d5489c4a991532f4`
- Preview: `assets/source/compound/dispensing_line/dispensing_line_meshy6_preview.png`

## Inputs (submission order — pipette rack ceiling crops 2026-10-31)
- `docs/art/compound/dispensing_line/meshy_inputs/wormseye_three_quarter.png` — 572296 B, sha256 `59b15eafb13f67a61cf4d853d4d8ea41704629c27f7aec19df99c9fa9a16e87f`
- `docs/art/compound/dispensing_line/meshy_inputs/front.png` — 423095 B, sha256 `3c302c8e08b6151761112ea29bf1079c8d97b5be971ab8c810972db10f6579b9`
- `docs/art/compound/dispensing_line/meshy_inputs/side.png` — 242192 B, sha256 `8c362adb1c3baa67c02d2edffe239d0896c8c32ec1a3e5b43f10da55c59a9ea0`
- `docs/art/compound/dispensing_line/meshy_inputs/underside.png` — 489594 B, sha256 `86bbc4b2725e112e2e07af4653974a9aca0f94ddab6a2c04e540c60e196014df`

Sheet: `docs/art/compound/dispensing_line/references/dispensing_line_pipette_rack_4view.jpg`

Evidence: `BUILD_EVIDENCE_meshy6.json`

## Structural inspect (Blender 5.2.0 LTS)

- triangles: 295,916
- vertices: 163,227
- dimensions (m): 1.900 × 0.503 × 1.052
- non_manifold_edges (welded): 0
- welded connected components: 1
- materials: Material_0
- Evidence: `INSPECT_meshy6.json`

Concept only. Ceiling-mounted pipette rack (~six tips). Retopo/dock to Dispensing Line greybox contract before runtime.

