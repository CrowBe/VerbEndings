# semantic_engine_panel — Meshy provenance (wave 4)

Evidence class: **Production Source (concept) — not runtime.** Requires tidy/retopo before any export.

- Provider: Meshy (multi-image-to-3d), model `meshy-6`
- Task ID: `01a1c286-6ff0-7025-a0a4-362fd6c44a9b` — status SUCCEEDED
- Created/finished (UTC): 2026-11-09T22:55:55.316000+00:00 / 2026-11-09T23:02:52.586000+00:00
- Credits: balance 770 → 740 (consumed 30; read live before and after this run, runs were sequential)
- Approval: "Let's run those. Any weak references we can rerun. Any strong ones without 3D models start handing off to Media Desk. You/Media Desk have approval for 150 meshy Credits" (Benjamin to VerbEndings Bench, 2026-11-10 09:45 AEDT; wave-4 cap 150 = 5 runs x 30)
- Prompt: none (multi-image-to-3d has no text prompt). Seed: none sent (Meshy default).
- Settings: should_texture=true, enable_pbr=true, hd_texture=true, texture_resolution=4k, should_remesh=false, remove_lighting=true, target_formats=[glb], no pose_mode
- Output: `assets/source/shared/semantic_engine_panel/semantic_engine_panel_meshy6_concept.glb` — 25395452 B, sha256 `c2b70915842d39cadca84d4ad5320a466b5df43a8a4c4937b70705a41362a56b`
- Preview: `assets/source/shared/semantic_engine_panel/semantic_engine_panel_meshy6_preview.png` — sha256 `c09956504f72af62df0fccf8375a2ac2c09923f0e2bae400b2bc8cd043b44e47` (Meshy thumbnail)

## Inputs (submission order)
- `docs/art/shared/semantic_engine_panel/meshy_inputs_wave4/front.png` — 787945 B, sha256 `0742adb3341c8bbd9a37a4571387fbef203e3a2d8493cd0bcf4d6181ef79e090`
- `docs/art/shared/semantic_engine_panel/meshy_inputs_wave4/side.png` — 505726 B, sha256 `be7823ee8f6c0f11e353f2e554a0421a8b06b75787032efdeb38290f9a9de9d6`
- `docs/art/shared/semantic_engine_panel/meshy_inputs_wave4/rear_three_quarter.png` — 606092 B, sha256 `1a4fb6510613b6eef65a296c08125d6c468b45916715ca709d8f7556deba65c2`
- `docs/art/shared/semantic_engine_panel/meshy_inputs_wave4/top.png` — 579915 B, sha256 `fe530b3409ce23077aa3748fbd81a947fbd20347afc2ecd2098735195f02c06b`

## Reference sheet
- Sheet: `docs/art/shared/semantic_engine_panel/references/semantic_engine_panel_wave4_sheet.png` — sha256 `098a8027d687d4805960e5d8439cdad0f248d7d062bfcf23cd3a9343ff7e40e6`
- Generation: Built-in Grok Imagine (GenerateImage, free), wave 4 2026-11-10. The production sheet docs/art/shared/references/semantic_engine_interfaces_production.png shows six separate modules in single 3/4 views only (no combined panel+printer unit, no orthographic views), so a combined floor console (display panel + card slot / receipt printer / dial+button control deck / plinth) was generated per view with that sheet and the facility material board as references, then composited with PIL (front, side, rear 3/4, top, front 3/4, 1.0 m capsule scale panel).

## Disclosed flaws
- Combined console is derived from the production sheet's monitor, printer and dial modules; not a crop of the original sheet (no orthographic views existed there).
- Top view is a high-angle near-plan: the display recess and sloped control deck faces are visible, not a strict 90-degree plan.
- Proportions read ~0.85 x 0.6 x 1.6 m, narrower than the brief's ~1.2 m envelope; scale in engine.
- Rear 3/4 back shell is plain (service hatch + vent only).

Evidence: `BUILD_EVIDENCE_meshy6.json`
