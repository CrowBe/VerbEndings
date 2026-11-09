# momentum_turbine — Meshy provenance (wave 4)

Evidence class: **Production Source (concept) — not runtime.** Requires tidy/retopo before any export.

- Provider: Meshy (multi-image-to-3d), model `meshy-6`
- Task ID: `01a1c293-e8f6-73c5-9968-b2a3fa3ee02a` — status SUCCEEDED
- Created/finished (UTC): 2026-11-09T23:10:38.590000+00:00 / 2026-11-09T23:13:49.058000+00:00
- Credits: balance 710 → 680 (consumed 30; read live before and after this run, runs were sequential)
- Approval: "Let's run those. Any weak references we can rerun. Any strong ones without 3D models start handing off to Media Desk. You/Media Desk have approval for 150 meshy Credits" (Benjamin to VerbEndings Bench, 2026-11-10 09:45 AEDT; wave-4 cap 150 = 5 runs x 30)
- Prompt: none (multi-image-to-3d has no text prompt). Seed: none sent (Meshy default).
- Settings: should_texture=true, enable_pbr=true, hd_texture=true, texture_resolution=4k, should_remesh=false, remove_lighting=true, target_formats=[glb], no pose_mode
- Output: `assets/source/applied_attrition/momentum_turbine/momentum_turbine_meshy6_concept.glb` — 37227284 B, sha256 `946c09390e833f1c5a81fe79ced365167d5ff81cadd1f1c317265b4a239cb818`
- Preview: `assets/source/applied_attrition/momentum_turbine/momentum_turbine_meshy6_preview.png` — sha256 `27b82aa08a9aa92ebc652086cc3282addae992ab065851da6aa91570e32214e0` (Meshy thumbnail)

## Inputs (submission order)
- `docs/art/applied_attrition/momentum_turbine/meshy_inputs_wave4/front.png` — 1002614 B, sha256 `938628a612e3f1d0d92137fa446b1f3a48af994f2f3f846f0810b39c0eba207e`
- `docs/art/applied_attrition/momentum_turbine/meshy_inputs_wave4/side.png` — 518863 B, sha256 `aad851923407c9b845a967dcd75e927c3c52d92b544b5d70a97ac5b7dab507b1`
- `docs/art/applied_attrition/momentum_turbine/meshy_inputs_wave4/rear_three_quarter.png` — 825851 B, sha256 `b3972e8b2efcb514a1a400f0114c529e025eea0352c6ec432ab8f775723d942b`
- `docs/art/applied_attrition/momentum_turbine/meshy_inputs_wave4/three_quarter.png` — 889313 B, sha256 `f079e26ff816a90dba72b10fc22b6fc6a98d279a57d53cf889481b15fe826c27`

## Reference sheet
- Sheet: `docs/art/applied_attrition/momentum_turbine/references/momentum_turbine_wave4_sheet.png` — sha256 `e6896caea01cb2be6d9b4dd69526b34b0cf6860d2a8afb714c2ffab10e0a18c2`
- States: `docs/art/applied_attrition/momentum_turbine/references/momentum_turbine_wave4_states.png` — sha256 `b09c3758eb1d4e6c085e20de5cbcd42aba0c7a235e3d1396b39838745bc8391b`
- Generation: Built-in Grok Imagine (GenerateImage, free), wave 4 2026-11-10; 3 design tries (try 1: pedestals left/right contradicted a face-on rotor; try 2: uneven paddle count/spacing). Passing design: cantilevered rotor, exactly six broad flat paddles at 60 degrees as interaction faces, caged hub, single bearing pedestal on a wide plinth, asymmetric chevron tip fins (all swept clockwise) as the direction cue. Moss clump from the material-board reference removed by an edit pass. Composited with PIL (rotor face-on, edge-on with axle, rear 3/4, top, front 3/4, 1.0 m capsule scale panel at ~5.6 m).

## Disclosed flaws
- Single cantilevered bearing pedestal rather than a two-sided bearing frame.
- Top panel is a high-angle near-plan (pedestal and paddles partly read as elevation); Meshy got front 3/4 instead of top.
- Meshy input naming: front.png = rotor face-on (sheet panel 1), side.png = edge-on with axle.
- States strip: jammed panel shows a missing lower paddle and a clamp in the cage; slow-spin blur is subtle.

Evidence: `BUILD_EVIDENCE_meshy6.json`
