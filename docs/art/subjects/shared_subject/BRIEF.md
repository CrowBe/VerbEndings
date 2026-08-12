# Shared Subject Meshy Pilot Brief

## Issue relationship

This visual-asset slice advances `CrowBe/VerbEndings#24` by drafting the shared Subject body and stable identity presentation from the project-owned video reference sheets. It does not implement the facility palette, lighting baseline, active per-Verb treatments, Critical Stability cues, animation integration, or the complete issue.

## Canon and role

A Subject is the living playable entity controlled by a Player during a Trial. It originates as a Semantic Adaptation Droplet (SAD). The Researcher alone may affectionately call a Subject a blob.

The pilot must read as clinical, buoyant, tactile, friendly, and quietly uncanny:

- soft jelly/droplet body with one curved peak;
- two glossy black oval eyes;
- no mouth, nose, eyebrows, ears, hair, or human face;
- two short jelly arms and two broad jelly feet;
- soft, slightly translucent substrate with believable stylised-PBR response;
- stable warm off-white laboratory jacket/suit treatment;
- no gore, body horror, third-party character language, weapons, or facility authority symbols.

The Subject is not the Semantic Engine and carries no avatar-like machinery.

## Shared geometry and identity boundary

This is one **shared Subject geometry pilot**, not three separately authored Verb bodies. The SHIELD, GROW, and BOUNCE sheets show the same anatomy and garment construction in different substrate tones. The GROW and BOUNCE sheets therefore validate cross-sheet consistency; the SHIELD sheet supplies the four Meshy input views.

Latest `main` governs the runtime boundary:

- stable Subject identity uses suit treatment and a number or replaceable identity panel;
- active Verb Effects remain temporary material, silhouette, icon, and motion treatments;
- claimed-Verb colour or text must not become a permanent geometry dependency;
- any letters, `SAD SHIELD` badge text, or barcode reconstructed by Meshy are concept artefacts to remove during Blender production cleanup.

## Approved references

Project-owned source sheets:

- `references/subject_shield_turnaround.png`
- `references/subject_grow_turnaround.png`
- `references/subject_bounce_turnaround.png`
- `references/subject_group_dispense_reference.png`

Meshy input crops:

- `meshy_inputs/subject_shield_front.png`
- `meshy_inputs/subject_shield_front_three_quarter.png`
- `meshy_inputs/subject_shield_side.png`
- `meshy_inputs/subject_shield_back.png`

The group dispensing image validates scale, cheerful mouthless performance, and shared anatomy only. It is not an image-to-3D input because it contains three posed Subjects and facility geometry.

## Dimensions, facing, and origin

- Runtime target height: approximately `1.2 m`, matching the current Subject capsule height.
- Body width excluding relaxed arms: approximately `0.9 m`.
- Relaxed presentation width including arms may extend modestly beyond the gameplay capsule, subject to camera and hit-readability review.
- Feet/contact surface at `Z=0`.
- Blender front is negative Y and maps to Godot positive Z.
- One predictable production root: `shared_subject` at identity transform.

Meshy auto-sizing is disabled for the concept. Blender owns exact metre scale, origin, facing, and applied transforms.

## Pilot generation contract

The first paid call is a high-detail multi-image **concept draft**:

- model selected explicitly before generation;
- four views of the same SHIELD Subject;
- standard character model;
- no automatic remesh;
- textured GLB only;
- PBR enabled, lighting removed from base colour;
- no animation, rig, collision, or embedded gameplay logic;
- retain exact task identifier, parameters, prompt/texture guidance, file hash, dimensions, topology evidence, and thumbnails.

The concept is not accepted as a runtime actor merely because generation succeeds.

## Production target after concept acceptance

A production Subject remains a deforming actor behind `scenes/Player.tscn`'s stable `Visual` and `AnimationAdapter` boundary. Blender production work must provide:

- clean deforming topology appropriate for a jelly body and short limbs;
- separable or controllable body substrate, eyes, suit, and identity-panel surfaces;
- no baked permanent Verb identity;
- a suitable skeleton and deformation tests;
- semantic animation clips from `docs/VISUAL_ASSET_PIPELINE.md`;
- editable `.blend` source under `assets/source/subjects/`;
- runtime GLB under `assets/exports/subjects/`;
- no gameplay collision in the GLB.

Godot retains `CharacterBody3D`, the capsule collision, hit area, camera rig, gameplay script, signals, sockets, and the `AnimationAdapter`.

## Concept acceptance checks

The Meshy draft passes concept review only if:

1. front, three-quarter, side, and back thumbnails agree on one coherent body;
2. the droplet peak, squat mass, stub feet, short arms, jacket opening, collar, and back panel all remain recognisable;
3. the face is exactly two black oval eyes with no mouth or added facial features;
4. no arms, feet, eyes, or jacket panels are missing, duplicated, fused incorrectly, or floating;
5. the jacket reads as a separate garment even if the concept topology is fused;
6. translucency and surface response preserve the soft substrate without looking glass-hard or opaque plastic;
7. no reference background, floor, text plate, facility machinery, or other Subject becomes geometry;
8. the output can serve as concept evidence for Blender retopology/reconstruction even if it is too dense or fused for rigging.

Concept acceptance does not establish animation quality, gameplay readability, rigging suitability, runtime budget, or Godot integration.
