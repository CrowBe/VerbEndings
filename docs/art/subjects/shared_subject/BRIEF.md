# Shared Subject Production-Source Brief

## Canon And Role

A Subject is the living playable entity controlled by a Player during a Trial. It originates as a Semantic Adaptation Droplet (SAD). The Researcher alone may affectionately call a Subject a blob.

The shared Subject reads as clinical, buoyant, tactile, friendly, and quietly uncanny:

- one soft jelly/droplet body with a curved peak;
- two glossy black oval eyes and no mouth, nose, eyebrows, ears, or hair;
- two short jelly arms and two broad jelly feet;
- a soft, slightly translucent substrate with believable stylised-PBR response;
- a stable warm off-white laboratory jacket or suit treatment; and
- rounded, simplified anatomy that deforms cleanly and remains readable from the third-person camera.

The Subject has no weapons, gore, body-horror treatment, facility authority symbols, or avatar-like machinery.

## Approved Production Sources

- `references/subject_neutral_production_turnaround.png` is the **primary** neutral common-anatomy turnaround for future Meshy / reconstruction (batch 1, 2026-10-23): mouthless, neutral cream substrate, no SAD SHIELD text, no barcode.
- `references/subject_shield_turnaround.png`, `subject_grow_turnaround.png`, and `subject_bounce_turnaround.png` remain lineage / Verb-colour consistency refs; markings and permanent Verb colour are not production identity.
- `references/subject_group_dispense_reference.png` confirms mouthless group performance and approximate scale.
- `meshy_inputs/` still holds SHIELD crops; regenerate crops from the neutral turnaround before the next paid Meshy run.

Written canon overrides generated details. The body colour in Verb-colour sheets does not permanently identify a Verb.

## Runtime Envelope

- Target height: approximately `1.2 m`, matching the gameplay capsule.
- Target body width excluding relaxed arms: approximately `0.9 m`.
- Feet and contact surface at `Z = 0` in Blender.
- Blender front is negative Y and maps to Godot positive Z.
- Predictable runtime root: `shared_subject` at identity transform.
- Target production geometry: `12,000–20,000` triangles; hard ceiling `25,000` before any profiling-driven LODs.

Godot owns `CharacterBody3D`, the capsule collision, hit area, camera rig, gameplay script, signals, sockets, and `AnimationAdapter`. The imported visual owns presentation only.

## Production Mesh Contract

The runtime actor provides:

- clean deforming topology around the droplet peak, shoulders, short arms, broad feet, jacket opening, and lower-body squash regions;
- independently controllable body substrate, eyes, suit, and identity-panel surfaces;
- a neutral default substrate and no baked claimed-Verb treatment;
- stable UVs and material masks suitable for temporary Verb treatments and Critical Stability deformation;
- a skeleton and skin suitable for locomotion, expressive arm motion, squash, stretch, landing compression, Impacts, and Destabilisation;
- the semantic animation clips documented in `docs/VISUAL_ASSET_PIPELINE.md`;
- applied transforms, metre scale, exact origin and facing, one predictable root, and no gameplay collision; and
- editable Blender source under `assets/source/subjects/` plus a runtime GLB under `assets/exports/subjects/`.

## Mesh Disposition (pruned)

Meshy concept GLBs (`shared_subject_meshy6_concept.glb`, `shared_subject_meshy6b_concept.glb`), their controlled `renders/`, and `BUILD_EVIDENCE*.json` were **pruned** (2026-10-23). The 3D design did not match the intended Subject. Do not retopo from those meshes. A future concept mesh requires a new approved Meshy run from the retained turnarounds / `meshy_inputs/`.

## Acceptance Evidence

A future runtime Subject is accepted only after a new approved concept mesh (or authored reconstruction), structural inspection, rig and deformation review, Godot 4.3 import, semantic-animation coverage, gameplay-camera readability, and hidden-visual boundary checks all pass. Exact generation parameters for pruned meshes remain in `PROVENANCE.md` for audit only.
