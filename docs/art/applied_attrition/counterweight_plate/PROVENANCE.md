# counterweight_plate — Meshy provenance (wave 4)

Evidence class: **Production Source (concept) — not runtime.** Requires tidy/retopo before any export.

- Provider: Meshy (multi-image-to-3d), model `meshy-6`
- Task ID: `01a1c297-6ac5-75b8-8181-67e974a757cc` — status SUCCEEDED
- Created/finished (UTC): 2026-11-09T23:14:28.018000+00:00 / 2026-11-09T23:18:52.750000+00:00
- Credits: balance 680 → 650 (consumed 30; read live before and after this run, runs were sequential)
- Approval: "Let's run those. Any weak references we can rerun. Any strong ones without 3D models start handing off to Media Desk. You/Media Desk have approval for 150 meshy Credits" (Benjamin to VerbEndings Bench, 2026-11-10 09:45 AEDT; wave-4 cap 150 = 5 runs x 30)
- Prompt: none (multi-image-to-3d has no text prompt). Seed: none sent (Meshy default).
- Settings: should_texture=true, enable_pbr=true, hd_texture=true, texture_resolution=4k, should_remesh=false, remove_lighting=true, target_formats=[glb], no pose_mode
- Output: `assets/source/applied_attrition/counterweight_plate/counterweight_plate_meshy6_concept.glb` — 40496636 B, sha256 `3cffabee9ccb9b7d10abd1cd2bae7b53619f4e4e580eda93979319bcade693c2`
- Preview: `assets/source/applied_attrition/counterweight_plate/counterweight_plate_meshy6_preview.png` — sha256 `952c8632547ddaccadcd66bb12ff48daa9851444be69c8936471f15ccc7a0a10` (Meshy thumbnail)

## Inputs (submission order)
- `docs/art/applied_attrition/counterweight_plate/meshy_inputs_wave4/front.png` — 690813 B, sha256 `e039bbec12e6a9cbf5d2178f1ce8356f360b041b03df695f742b3df7a3354879`
- `docs/art/applied_attrition/counterweight_plate/meshy_inputs_wave4/side.png` — 562561 B, sha256 `9f210680c59d2fa2a94bdf87b33191676707f3975ecd3f4fdc0e372350614808`
- `docs/art/applied_attrition/counterweight_plate/meshy_inputs_wave4/rear_three_quarter.png` — 609439 B, sha256 `ca484718a31e6f9d913a006f8510d9c88edc40df74aa586a05450ff44890d126`
- `docs/art/applied_attrition/counterweight_plate/meshy_inputs_wave4/three_quarter.png` — 596767 B, sha256 `f3bd8597ea3f18144ff793c9fe1cf39e541aa8c8e0277e1295ad2bebaf0e769c`

## Reference sheet
- Sheet: `docs/art/applied_attrition/counterweight_plate/references/counterweight_plate_wave4_sheet.png` — sha256 `b40192a9d231639c11ed9c18c304fca4ab9c5f3f4653e8ea7d8a9ffb908e8d4a`
- States: `docs/art/applied_attrition/counterweight_plate/references/counterweight_plate_wave4_states.png` — sha256 `71a5787a3bd3581d57a72db902d0d0ca4f3508b80d70f7f27ceb47182485b01f`
- Generation: Built-in Grok Imagine (GenerateImage, free), wave 4 2026-11-10; 2 design tries (try 1: see-saw lever not attached to plate or crates). Passing design: ~3x3 m lift plate in a floor pit with guide posts, cable over a sheave on a lattice gantry tower to a three-crate mass stack in an open guide cage, chunky toothed ratchet wheel + pawl latch threshold at the tower base. Side elevation master; front, rear (opposite side), plan and front 3/4 generated from it; composited with PIL (1.0 m capsule scale panel at ~4.2 m).

## Disclosed flaws
- Cable is thin and will reconstruct poorly in Meshy; expect to rebuild it as a spline/cylinder.
- Rear view is a near-side elevation from the opposite side, not a true rear 3/4.
- Plate-to-tower force path is cable/sheave, not a rigid lever; reads as lift, not launch.
- States strip: panels 1-3 from one render (panel 3 'tripped' differs little from panel 2); panel 4 'launched' is a separate render at a different zoom, crates outside the lower cage.
- Meshy inputs: front, side, rear (opposite side), front 3/4; plan view kept as a crop and on the sheet but not submitted.
- Post-run check (vertex projection): plate-to-sheave cable span not reconstructed (only sheave-to-crate cable present); tower/cage read taller relative to the plate than on the sheet; plate sits right against the tower footprint.

Evidence: `BUILD_EVIDENCE_meshy6.json`
