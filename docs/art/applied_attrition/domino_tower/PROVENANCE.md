# domino_tower — Meshy provenance (wave 4)

Evidence class: **Production Source (concept) — not runtime.** Requires tidy/retopo before any export.

- Provider: Meshy (multi-image-to-3d), model `meshy-6`
- Task ID: `01a1c2af-6d15-7585-b195-bade23740dee` — status SUCCEEDED
- Created/finished (UTC): 2026-11-09T23:40:41.022000+00:00 / 2026-11-09T23:43:24.051000+00:00
- Credits: balance 620 → 590 (consumed 30; read live before and after this run, runs were sequential)
- Approval: Extra run beyond the 150-credit wave-4 cap, approved separately for 30 credits: Benjamin "Yeah use more" (10:40 AEDT 2026-11-10, in reply to 'a domino tower model would need another 30'), and via VerbEndings Bench "Yes, spend 30 on the domino tower". Stable form only.
- Prompt: none (multi-image-to-3d has no text prompt). Seed: none sent (Meshy default).
- Settings: should_texture=true, enable_pbr=true, hd_texture=true, texture_resolution=4k, should_remesh=false, remove_lighting=true, target_formats=[glb], no pose_mode
- Output: `assets/source/applied_attrition/domino_tower/domino_tower_meshy6_concept.glb` — 36453856 B, sha256 `5edc80edc64a38ac798338b1d7de654aaf0b1069c95d5921be1487f581dbf1de`
- Preview: `assets/source/applied_attrition/domino_tower/domino_tower_meshy6_preview.png` — sha256 `d005615ba089edd977ed175993f6cb50c8beb691a48857162298750ce4ed8758` (Meshy thumbnail)

## Inputs (submission order)
- `docs/art/applied_attrition/domino_tower/meshy_inputs_wave4/front.png` — 647662 B, sha256 `cf63f8426d0be001a725221ee6ead59d66f8e325b2823631d3707a55b31c8030`
- `docs/art/applied_attrition/domino_tower/meshy_inputs_wave4/side.png` — 516465 B, sha256 `50aaec0e9dd62aa8f8186207b0739bd7579d091d49602f107f1993b8ab292dd7`
- `docs/art/applied_attrition/domino_tower/meshy_inputs_wave4/three_quarter.png` — 719073 B, sha256 `92aa4cae49ddc42c3e5bee62243b00a8fbbbb3453eedad2ab357dec417a93ed4`

## Reference sheet
- Sheet: `docs/art/applied_attrition/domino_tower/references/domino_tower_wave4_sheet.png` — sha256 `55762573205c7c46866e9068fe30cb3f50c541e4d3eb9f3c0f30020dbc36ad96`
- States: `docs/art/applied_attrition/domino_tower/references/domino_tower_wave4_states.png` — sha256 `38a3a9dac7f793969fb1b4781c26ad07e52e9cc70a971183a63a84056f7ab525`
- Generation: Built-in Grok Imagine (GenerateImage, free), wave 4 2026-11-10; front elevation master (try 2; try 1 was a 3/4 with cube blocks), side, front 3/4, near-plan top generated from it; composited with PIL (1.0 m capsule scale panel at ~8 m). Crops on main via PR #96.

## Disclosed flaws
- Meshy inputs: front, side, front 3/4 only (stable form). The near-plan top crop was not submitted: it is high-angle and shows a square crown, but the brief has a 3x1.5 m crown.
- Blocks are stacked in aligned 2-per-course columns, not running bond; faces read ~1.5x1 m rather than 1x1x2 m.
- No rear panel (front/back symmetric).
- States strip: the fully toppled panel shows fewer blocks than the stable tower.
- Post-run check: the model footprint came out square (extents ~0.63 x 1.9 x 0.63 normalised, ~2.65 x 8 x 2.65 m at 8 m tall), not 3 x 1.5 m. The side depth was not kept.
- Post-run preview: base-course cracks are faint in the texture, but the clamps read. The tower is one fused mesh, so the blocks need to be separated for the topple states.

Evidence: `BUILD_EVIDENCE_meshy6.json`
