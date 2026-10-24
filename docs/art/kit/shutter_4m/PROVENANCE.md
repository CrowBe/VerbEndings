# shutter_4m — Meshy provenance

Evidence class: **Production Source (concept) — not runtime.** Requires tidy/retopo before any export.

- Service: Meshy (multi-image-to-3d), model `meshy-6`
- Task ID: `01a17017-157c-7496-84b1-db3322645fc9` — status SUCCEEDED
- Created/finished (UTC): 2026-10-24T22:45:24.109000+00:00 / 2026-10-24T22:49:01.010000+00:00
- Credits: before 950, after 920, consumed 30 (approved cap 30; Benjamin OK t47s223)
- Settings: should_texture=true, enable_pbr=true, hd_texture/texture_resolution=4k, should_remesh=false, remove_lighting=true, target_formats=[glb], no pose_mode
- Output: `assets/source/kit/shutter_4m/shutter_4m_meshy6_concept.glb` — 36412780 B, sha256 `ce3046c6052907a321ecf6428b09b2d84e6e6fad574530abedb414d0c87026b3`

## Inputs (in submission order, from sheet-batch-2 crops b7d4b31)
- `docs/art/kit/shutter_4m/meshy_inputs/front_closed.png` — 103316 B, sha256 `720fa8d69aa6f942f6965ad73b7a7810de5959c07ee900fb4bb7ed841452f4e1`
- `docs/art/kit/shutter_4m/meshy_inputs/rear_three_quarter.png` — 108594 B, sha256 `56fea31042b3edf6e58a249dfbda3ae0aa542b7b500bcbca4e3e7cbf499b41a1`

Evidence: `BUILD_EVIDENCE_meshy6.json`

## Structural inspect (Blender 5.2.0 LTS)

- triangles: 679,384
- vertices: 384,236
- dimensions (m): 1.671 × 0.331 × 1.900
- non_manifold_edges (welded): 0
- welded connected components: 9
- materials: Material_0
- Evidence: `INSPECT_meshy6.json`

Concept only. **Scale note:** mesh reads ~1.67×0.33×1.90 m — not a true 4 m span; rescale/retopo to kit contract. Welded components: 9.
