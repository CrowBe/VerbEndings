# wrecking_pendulum — Meshy provenance (wave 4)

Evidence class: **Production Source (concept) — not runtime.** Requires tidy/retopo before any export.

- Provider: Meshy (multi-image-to-3d), model `meshy-6`
- Task ID: `01a1c28e-c8f6-751e-907c-38a23ae808dd` — status SUCCEEDED
- Created/finished (UTC): 2026-11-09T23:05:02.174000+00:00 / 2026-11-09T23:09:25.496000+00:00
- Credits: balance 740 → 710 (consumed 30; read live before and after this run, runs were sequential)
- Approval: "Let's run those. Any weak references we can rerun. Any strong ones without 3D models start handing off to Media Desk. You/Media Desk have approval for 150 meshy Credits" (Benjamin to VerbEndings Bench, 2026-11-10 09:45 AEDT; wave-4 cap 150 = 5 runs x 30)
- Prompt: none (multi-image-to-3d has no text prompt). Seed: none sent (Meshy default).
- Settings: should_texture=true, enable_pbr=true, hd_texture=true, texture_resolution=4k, should_remesh=false, remove_lighting=true, target_formats=[glb], no pose_mode
- Output: `assets/source/applied_attrition/wrecking_pendulum/wrecking_pendulum_meshy6_concept.glb` — 38149148 B, sha256 `52c562a81fc0ee5dfb82cacb5bb0a847fd73b83ecdbd3617cec050f9dc85abe6`
- Preview: `assets/source/applied_attrition/wrecking_pendulum/wrecking_pendulum_meshy6_preview.png` — sha256 `12f3b4a043c3c72db772e8175c4bac0184070e135dc1e5b63138373d7b1ec7a8` (Meshy thumbnail)

## Inputs (submission order)
- `docs/art/applied_attrition/wrecking_pendulum/meshy_inputs_wave4/front.png` — 818162 B, sha256 `6738493ec2b429bbbd15be1c034ccc079bb035713afa933af3b8ff115c51ea19`
- `docs/art/applied_attrition/wrecking_pendulum/meshy_inputs_wave4/side.png` — 630162 B, sha256 `7c6ab170c6a81d020d5ba2bb53a6ebb1a81efaf97f591374e099085919d9e2fe`
- `docs/art/applied_attrition/wrecking_pendulum/meshy_inputs_wave4/rear_three_quarter.png` — 607096 B, sha256 `25a5fa2dc7b0d8d0340555909d26f06384b813f9ed37f5ec160b3489127a2143`
- `docs/art/applied_attrition/wrecking_pendulum/meshy_inputs_wave4/top.png` — 552300 B, sha256 `dcea905a16585efc1f4db2893bc1cd4363b4eba578250ef2a2d855bf1abdc4c7`

## Reference sheet
- Sheet: `docs/art/applied_attrition/wrecking_pendulum/references/wrecking_pendulum_wave4_sheet.png` — sha256 `ab367b7aedccb460c4f18f232a5592d6ed7183ea6b47e3d436ce79a4642f8c3f`
- States: `docs/art/applied_attrition/wrecking_pendulum/references/wrecking_pendulum_wave4_states.png` — sha256 `262f485f3d43f36c153fd8439b596f8f7f2efde6a89ba5bf9b307ac469f555e2`
- Generation: Built-in Grok Imagine (GenerateImage, free), wave 4 2026-11-10; 3 design tries (tries 1-2 rejected: target wall beside the frame, inconsistent with swing plane). Passing design: swing-set gantry (crossbeam + A-frame ends), oversized pin joint, rigid box-beam arm, faceted bob, separate reinforced target wall in the swing line, raised curved kerb as arc geometry. Side elevation generated first as master; front, rear 3/4, plan and front 3/4 generated from it; composited with PIL (front, side, rear 3/4, top, front 3/4, 1.0 m capsule scale panel at ~6 m).

## Disclosed flaws
- No strict rear orthographic panel; rear 3/4 used (apparatus is front/back symmetric).
- Front 3/4 panel places the target wall slightly offset right of the swing line versus the side elevation.
- Floor arc kerb is a short separate segment, not a full 8 m arc; bob face detail varies slightly between views.
- States strip: panel 2 (narrow swing) reads almost identical to rest.

Evidence: `BUILD_EVIDENCE_meshy6.json`
