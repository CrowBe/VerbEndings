# Shared Subject (SAD) — @tanstack/ai-meshy chain provenance

The rigged Shared Subject and the prompted idle and walk are runtime exports under `assets/exports/subjects/shared_subject/`. `Player.tscn` instances the rigged visual and uses the shared locomotion library at `assets/animation/shared_subject_locomotion.tres`.

## Approval

Benjamin, via Grok Bot, at 21:04 AEDT (Australia/Sydney) on 23 Nov 2026: “Go with the recommended plan, 61 credits OK.” That approved only this chain: mesh 30, rig 5, prompted 3 s idle and 3 s walk with their applies 26. No Ultra geometry, no 8K, no SHIELD crops, no library-clip fallback, no `meshyrig` fallback, no retry of a failed paid step.

## Provider and package

- Service: Meshy API (`https://api.meshy.ai/openapi`)
- Client: `@tanstack/ai-meshy` 0.1.0 with `@tanstack/ai` 1.8.0
- Runtime: Node v24.22.1
- Script: `/workspace/tsmeshy/run-chain.mjs` (copy at `/workspace/w5/shared_subject_chain/run/run-chain.mjs`)
- `MESHY_API_KEY` was read from the environment only and is not recorded here
- Thread id: `shared-subject-sad-chain`
- Run window: 23 Nov 2026, 21:08:31–21:14:25 AEDT (Australia/Sydney)

## Inputs

Cleaned crops from `docs/art/subjects/shared_subject/references/subject_neutral_production_turnaround.png` (SHA-256 `6c488cc9e618798e22f8942fa99ef78d7e8947b7759ac90bf682c2a5304a50e9`). Front is first.

| View | Path | SHA-256 | Bytes |
| --- | --- | --- | --- |
| Front | `/workspace/w5/shared_subject_chain/inputs/subject_neutral_front_clean.png` | `f34d9d59d97cdb0acddeeac7d85d2e9da3ed623ce5e7bce32cb8c622edda67f0` | 160601 |
| Front 3/4 | `/workspace/w5/shared_subject_chain/inputs/subject_neutral_front_three_quarter_clean.png` | `a82fdf4f4e2a21ed974a7a7f044ebb1c31127d4cfbcb399645602a5199cbfc17` | 144453 |
| Side | `/workspace/w5/shared_subject_chain/inputs/subject_neutral_side_clean.png` | `8af9144b92ed410bb487d00857bd665da7de449fefc7d0598136ddd0f76da1b8` | 123889 |
| Back | `/workspace/w5/shared_subject_chain/inputs/subject_neutral_back_clean.png` | `dc894ccd0a4e3d6bad05c5a85494ab283f69a1497e7a0cf4f8e9feb07b7bff1e` | 151830 |

## Credits

Opening balance: **1500** (1000 monthly + 500 permanent). Closing balance: **1439** (939 monthly + 500 permanent). Confirmed by a later read-only GET. Total spent: **61**. Monthly reset: 23 Dec 2026, 08:13 AEDT (Australia/Sydney).

| Step | Endpoint | Task id | Budget | `consumed_credits` | Balance before → after | Running total |
| --- | --- | --- | --- | --- | --- | --- |
| 1. Mesh | `POST /v1/multi-image-to-3d` | `01a207e0-edcf-7340-96da-77dfe843cb9a` | 30 | 30 | 1500 → 1470 | 30 |
| 2. Rig | `POST /v1/rigging` | `01a207e4-4b59-7173-a256-39d479d24226` | 5 | 5 | 1470 → 1465 | 35 |
| 3. Idle motion | `POST /v1/text-to-motion` | `01a207e4-f320-7331-94bc-0ca235d49a92` | 10 | 10 | 1465 → 1455 | 45 |
| 4. Idle apply | `POST /v1/animations` | `01a207e5-5681-744c-bea4-3b421eb5b906` | 3 | **3** | 1455 → 1452 | 48 |
| 5. Walk motion | `POST /v1/text-to-motion` | `01a207e5-bbef-72dc-8f85-eeb87577f1fc` | 10 | 10 | 1452 → 1442 | 58 |
| 6. Walk apply | `POST /v1/animations` | `01a207e5-efe8-7169-bf15-18f9c0f83c60` | 3 | **3** | 1442 → 1439 | **61** |

Every step stayed on budget. Both apply steps billed the published Animation price of 3. Machine-readable log: `/workspace/w5/shared_subject_chain/run/state.json`.

## Settings

### 1. Multi-image to 3D

- `ai_model`: `meshy-6`
- `should_texture`: true
- `enable_pbr`: true
- `texture_resolution`: `4k`
- `remove_lighting`: true
- `image_enhancement`: true
- `pose_mode`: `t-pose`
- `should_remesh`: true
- `topology`: `triangle`
- `target_polycount`: 20000
- `save_pre_remeshed_model`: true
- `origin_at`: `bottom`
- `alpha_thumbnail`: true
- `multi_view_thumbnails`: true
- `target_formats`: `["glb"]`
- `name`: `shared_subject_neutral_meshy6_concept`

Result geometry: remeshed mesh **20,548** triangles (target 20,000); pre-remesh **218,250** triangles. Raw remeshed bounds about 1.90 × 1.82 × 0.62 m, centred, floor not at Y = 0. The later rig step applies the 1.2 m height and floor contact.

### 2. Rigging

- Chained from mesh task id via `input_task_id`
- `animation_type`: `biped`
- `height_meters`: 1.2
- `skeleton_template`: `mixamo`
- `include_fingers`: false
- `name`: `shared_subject_neutral_rig`

Result: one skin, **28** bones with Mixamo names (`mixamorig:Hips`, spine, neck, head, shoulders, arms, hands, `LeftHandMiddle4` / `RightHandMiddle4` end bones, legs, feet, toes). No finger chains. Skin weights are present and sum to 1.0 on every vertex (no zero-weight verts). Rest-pose bounds: width 1.25 m, height **1.200 m**, depth 0.41 m, floor at **Y = 0**. Y-up. Root node `Armature`. The rig task also returned bundled walking and running clips at no extra published charge; they are not used for the runtime locomotion clips.

### 3–6. Motion and apply

Idle prompt (prime, duration 3):

> A small plump droplet character in a lab coat idles in place, soft breathing and a gentle body squash, arms relaxed at the sides, looping, no locomotion

Walk prompt (prime, duration 3):

> A small plump droplet character in a lab coat walks forward with short steps, soft squash and stretch, arms swinging gently, looping locomotion

Each motion job was applied with `meshy3DModel('animation')`, `rig_task_id` = the rig task, `motion_task_id` = the motion task. Both applied clips are named `retarget_clip` and last **2.967 s**.

- Idle: essentially in place. `mixamorig:Hips` range is about 1.3 cm (X) × 0.2 cm (Y) × 0.5 cm (Z). Start and end differ by about 1.1 cm on X, so a loop may hitch slightly.
- Walk: **root motion**, not in place and not a loop. Hips travel about **+0.68 m in X** and **+1.86 m in Z** over the clip (about 0.67 m/s along +Z if +Z is forward), with a small Y bounce (~5 cm range). Start and end poses are far apart.

## Runtime exports

| File in `assets/exports/subjects/shared_subject/` | SHA-256 | Bytes |
| --- | --- | --- |
| `shared_subject_meshy6_chain_rigged.glb` | `3c6108103de13164853d93706fff4d4e708258ca956c9c399b88d83ad130481e` | 20991664 |
| `shared_subject_meshy6_chain_idle.glb` | `f46dbbb62a27c33716fe5dc6f9d1d064d8319631169b6ba5ba73a46cf093de3d` | 21181732 |
| `shared_subject_meshy6_chain_walk.glb` | `7dc95d7c6a4e735fd43089b5ef7bb8690f8c36207fb4f21549fa91b6f7e223f5` | 21181700 |

## Runtime presentation and inspection

The Player retains its 1.2 m high, 0.45 m radius gameplay capsule and uses one skinned rigged visual. The imported character faces Godot +Z with no additional scale or rotation. The rest-pose rig is Y-up with feet at Y = 0; its T-pose is 1.25 m wide and 1.2 m high. The coat and body share one mesh and deform with the skeleton. The substrate reads paler and cooler than the warm cream reference, and the body is fuller through the belly and coat. PBR maps include base colour, metallic-roughness, normal and emissive.

The shared library contains looping `idle` and `move` clips derived from the respective `retarget_clip` animations. The prompted walk keeps its vertical hip bob and both clips loop. Start and end hip poses match after a final-frame blend, but the `move` clip still carries about 0.36 m of mid-cycle hip XZ travel before returning, so some loop-seam slide remains. Gameplay moves the CharacterBody3D. Gameplay moves the CharacterBody3D. Other semantic actions use the adapter's existing fallbacks where available, including the proxy fist for `basic_hit`.

The source previews were inspected using headless three.js r170 and Chrome. The idle and walk deform the coat, arms and legs without obvious exploding vertices or broken necks in those frames. The original clips each last 2.967 seconds; idle has subtle breathing and squash, and the prompted walk has stepping and arm swing.
