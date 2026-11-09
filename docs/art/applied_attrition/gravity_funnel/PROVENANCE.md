# gravity_funnel — Meshy provenance (wave 4)

Evidence class: **Production Source (concept) — not runtime.** Requires tidy/retopo before any export.

- Provider: Meshy (multi-image-to-3d), model `meshy-6`
- Task ID: `01a1c29b-e03e-74e4-b8d6-8b86ce3cacee` — status SUCCEEDED
- Created/finished (UTC): 2026-11-09T23:19:20.343000+00:00 / 2026-11-09T23:22:59.666000+00:00
- Credits: balance 650 → 620 (consumed 30; read live before and after this run, runs were sequential)
- Approval: "Let's run those. Any weak references we can rerun. Any strong ones without 3D models start handing off to Media Desk. You/Media Desk have approval for 150 meshy Credits" (Benjamin to VerbEndings Bench, 2026-11-10 09:45 AEDT; wave-4 cap 150 = 5 runs x 30)
- Prompt: none (multi-image-to-3d has no text prompt). Seed: none sent (Meshy default).
- Settings: should_texture=true, enable_pbr=true, hd_texture=true, texture_resolution=4k, should_remesh=false, remove_lighting=true, target_formats=[glb], no pose_mode
- Output: `assets/source/applied_attrition/gravity_funnel/gravity_funnel_meshy6_concept.glb` — 26523160 B, sha256 `bd7e1726c5973963d35192eb207cc648bf1c2fd823caddbb0a5522b3f9f4f4ea`
- Preview: `assets/source/applied_attrition/gravity_funnel/gravity_funnel_meshy6_preview.png` — sha256 `14f6214c6235924352b40f0433adbfeff724a0fd639dedcd1f4bce59791ea96d` (Meshy thumbnail)

## Inputs (submission order)
- `docs/art/applied_attrition/gravity_funnel/meshy_inputs_wave4/front.png` — 425070 B, sha256 `7ba654d8eb43f0e9f373a98aead7938bbe91bc44be87b04142e9109d4d70b856`
- `docs/art/applied_attrition/gravity_funnel/meshy_inputs_wave4/rear_three_quarter.png` — 726351 B, sha256 `b91962774695d6558ab0841705ea57fbfec78f97f0f4d5d366a9b9181f735537`
- `docs/art/applied_attrition/gravity_funnel/meshy_inputs_wave4/top.png` — 1129190 B, sha256 `d9eddb1536438ec224225cc145a7efadb31a43755dcdae66cbf739d096af0b89`
- `docs/art/applied_attrition/gravity_funnel/meshy_inputs_wave4/three_quarter.png` — 903949 B, sha256 `64890a1c47337fcee93e309b642b360d50ba34edf546c1d9feeed819878b179c`

## Reference sheet
- Sheet: `docs/art/applied_attrition/gravity_funnel/references/gravity_funnel_wave4_sheet.png` — sha256 `b11ffc87c5353f5eb7eec298f283f32bfda987a9609ba9da6e173569aa021ae4`
- States: `docs/art/applied_attrition/gravity_funnel/references/gravity_funnel_wave4_states.png` — sha256 `8bfeb2d69b5061159eb6f2649789e63d510c0ef59b770aef28002b856cd2c89f`
- Generation: Built-in Grok Imagine (GenerateImage, free), wave 4 2026-11-10; passed first try. Shallow banked ~6 m basin, raised charcoal rim with eight ring-emitter coil units (bounded cyan), central intake throat with iris collar and hex grate, loose test balls as separate props. 3/4 master; front elevation, plan and low rear 3/4 generated from it; composited with PIL (1.0 m capsule scale panel).

## Disclosed flaws
- Radially symmetric: no separate side panel (equals front); one empty sheet cell.
- Test balls are baked into the input images and may fuse to the floor/rim in Meshy; split off in cleanup.
- Basin is raised above floor on an outer wall, not sunk flush into the floor.
- Meshy inputs: front elevation, low rear 3/4, plan, high front 3/4.
- Post-run preview: two front test balls are fused into the mesh below the rim, and the basin interior textured mid-grey rather than off-white.

Evidence: `BUILD_EVIDENCE_meshy6.json`
