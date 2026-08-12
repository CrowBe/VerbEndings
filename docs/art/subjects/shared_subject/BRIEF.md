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

- `references/subject_shield_turnaround.png` is the primary common-anatomy turnaround.
- `references/subject_grow_turnaround.png` and `references/subject_bounce_turnaround.png` confirm the shared anatomy across different generated substrate colours.
- `references/subject_group_dispense_reference.png` confirms mouthless group performance and approximate scale.
- `meshy_inputs/` contains the exact unretouched crops used to create the retained high-detail concept mesh.
- `assets/source/subjects/shared_subject/shared_subject_meshy6_concept.glb` is the retained three-dimensional shape source.
- `renders/` contains controlled `1.2 m`-high review views of that mesh.

Written canon overrides generated details. The body colour in these sources does not permanently identify a Verb. `SAD SHIELD` text, barcode marks, and generated rear status details are concept artefacts rather than production identity.

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

## Retained Mesh Disposition

`shared_subject_meshy6_concept.glb` is a **Production Source**, not a runtime model. It preserves the approved silhouette, two-eye mouthless face, short arms, broad feet, jacket, pockets, and rear garment panel well enough to guide retopology or reconstruction.

It does not satisfy the Production mesh contract because it contains `271,798` triangles in one fused mesh and one material, has no skin or animations, uses a vertically centred source origin, is approximately `1.899 m` high before normalisation, and bakes generated Verb-specific markings into its texture. It remains outside `assets/exports/` and is not referenced by `Player.tscn`.

## Acceptance Evidence

The focused source package retains exact generation parameters, hashes, topology, dimensions, facing, controlled renders, and source disposition in `BUILD_EVIDENCE.json` and `PROVENANCE.md`. A future runtime Subject is accepted only after structural inspection, rig and deformation review, Godot 4.3 import, semantic-animation coverage, gameplay-camera readability, and hidden-visual boundary checks all pass.
