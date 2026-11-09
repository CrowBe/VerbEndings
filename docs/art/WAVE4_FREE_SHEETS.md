# Wave 4 free sheets index (Media Desk)

Built-in GenerateImage only, 0 credits. Composited with PIL (`/workspace/w4/free/build06.py`, raw gens in `/workspace/w4/free/gen/`). Nothing committed.

## Batch 1 - 06 Subject Verb Effects

Layout per sheet: left = front/side/3/4 turnaround of the effect on the neutral Subject, right = action panel. 2904x1072 PNG. All prompts shared the base: "exact same small Subject character from the reference image: pearl-white translucent glossy droplet body, pointed teardrop head, two black eyes, long off-white lab coat ... body and coat stay pearl-white, not tinted ... neutral soft studio lighting, plain light warm-grey seamless background, soft contact shadow, full silhouettes, stylised PBR toy render. No text, no letters, no labels, no barcodes, no logos." Reference: `subject_neutral_production_turnaround.png`.

### BURN
- Path: `docs/art/subjects/shared_subject/references/verb_burn_wave4_sheet.png`
- sha256: `4fdb26d5200670f44c78a98a2a1647e68b69ef59ea0d986342024c29515b908e`
- Prompt: Turnaround: neutral Subject (ref subject_neutral_production_turnaround) front/side/3/4; tight #FF6A3D flames hugging outline, sparse embers, teardrop glyph. Action: sprint shoulder-barge into grey padded block, flame trail, scorch.
- Flaws: Turnaround view order is front / 3/4 / side (not front/side/3/4). Action panel: flame glow tints body orange (flame-on-body, not suit colour). Greyscale read relies on flame-edge silhouette, moderate.

### SHIELD
- Path: `docs/art/subjects/shared_subject/references/verb_shield_wave4_sheet.png`
- sha256: `5f48c40ed3039953d469658de28741b144260505c0277aaef01ae8103de07892`
- Prompt: Turnaround: thick translucent #35BCEB capsule shell with visible thickness, faint impact ripples, [ ] bracket glyph. Action (ref = wave4 shield turnaround): braced inside shell bubble, steel ball deflecting, concentric impact rings.
- Flaws: Bracket glyph renders as literal "[ ]" characters (icon, not text, but reads type-like). Action shell has a doubled rim outline. Shell is thin-ish in turnaround side view.

### GROW
- Path: `docs/art/subjects/shared_subject/references/verb_grow_wave4_sheet.png`
- sha256: `9f898dba0eee25c24db86d0f0d903267656f00161b61056fb080c2bd0c70321c`
- Prompt: Turnaround (v2): three pairs front/side/3/4 - normal Subject beside GROWN Subject, #66C95A floor pressure-pulse rings, nested-squares-with-arrows glyph. Action: grown Subject stomps, pulse ring pushes two normal Subjects back.
- Flaws: Grown figure in turnaround is only ~1.15x taller (mainly wider), not the ~1.6-1.7x asked; action panel shows the scale gap better. Pulse rings under both figures of each pair.

### STRETCH
- Path: `docs/art/subjects/shared_subject/references/verb_stretch_wave4_sheet.png`
- sha256: `fda27df5b705a63cfab8ad487668f900c204fa455ceb042101abc90c33984b99`
- Prompt: Turnaround (v3): vertically elongated ~2x height, long neck, tall narrow coat, long legs, magenta #D45AC7 tapered trails off head tip and feet, vertical double-arrow glyph. Action: arm stretched taffy-long to grab high ledge, magenta trails.
- Flaws: Magenta trails blend into head tip and feet so the body tips read magenta-tinted. Glyph is black/white not magenta. Turnaround side view nearly matches front.

### ROLL
- Path: `docs/art/subjects/shared_subject/references/verb_roll_wave4_sheet.png`
- sha256: `db94ecdc2103e68056d9434f2bf4722757615e3677194e210199f691be8377f0`
- Prompt: Turnaround: compact ball tuck, coat as band, #4169D8 arc trails, circular-arrow glyph. Action (v2, ref = roll turnaround): ball rolling with arc trails.
- Flaws: Ball keeps the teardrop head tip (egg/onion form, not a true sphere). Action reads as spinning in place more than travelling; no floor path.

### JUMP
- Path: `docs/art/subjects/shared_subject/references/verb_jump_wave4_sheet.png`
- sha256: `cb79952e3711cb54add33d20dd331998dcc47151b68ac20d535996176ab0e4e3`
- Prompt: Turnaround (v2): crouched loaded-spring wind-up, feet on floor, thin #F2C94C vertical streaks, coil glyph. Action (v2, ref = jump turnaround): launch high, thin vertical speed lines, take-off dust ring.
- Flaws: Coil-spring glyph is a 3D-looking spiral rather than a flat icon. Turnaround 3/4 and side are similar angles.

### BOUNCE
- Path: `docs/art/subjects/shared_subject/references/verb_bounce_wave4_sheet.png`
- sha256: `4e27cc0eadf9253624a0c6a11e1520bd88b6dbab006ae89051ceb657103f27ba`
- Prompt: Turnaround (v2): squashed wide jelly on floor impact, #FF7DB5 rebound ring, sine-wave glyph. Action: squash against wall with pink rebound ring, dotted rebound arc to stretched second pose.
- Flaws: Squash is moderate (~0.75 height) not the half-height asked. Action wall-contact pose is not visibly squashed; the wave glyph in the action is white.

### FREEZE
- Path: `docs/art/subjects/shared_subject/references/verb_freeze_wave4_sheet.png`
- sha256: `36a1127948b28d096727ff184f852159e95e4ad4c4bd135cb0a4fb60ffb3e45d`
- Prompt: Turnaround: frosted #A8E8E8 ice-crystal hands/feet, crystal shards at feet, snowflake-padlock glyph. Action: frozen mid-stride sliding on ice patch, crystals on head/back/limbs.
- Flaws: Head tip not frosted in turnaround (hands/feet only). Action has more crystal cover than "extremities" (back and head too).

### REWIND
- Path: `docs/art/subjects/shared_subject/references/verb_rewind_wave4_sheet.png`
- sha256: `4733d49bb7f068e1dd534f7288906e5395413dc59e167019b22387a0f7c5de79`
- Prompt: Turnaround: two violet #8067D8 ghost echoes offset behind, reverse ribbons spiralling, clock glyph. Action: snapping back along a line of four fading echoes, violet ribbon loop.
- Flaws: Clock glyph has no counter-clockwise arrow. Echoes are low contrast in greyscale (readable but faint). Ribbon in action is a flat ring, not a reverse ribbon.

### Greyscale check strip
- Path: `docs/art/subjects/shared_subject/references/verb_effects_greyscale_check_wave4.png`
- sha256: `4da9f88ad1f7e6076824c0ee1b40862bbee9cda0d59d2f9ab8a1ffbc466b8956`
- Content: top row = front view of each turnaround, bottom row = action panel, all greyscale, order BURN SHIELD GROW STRETCH ROLL JUMP BOUNCE FREEZE REWIND.
- Read: SHIELD (shell), STRETCH (tall), ROLL (ball), JUMP (crouch/launch), FREEZE (crystal spikes) read clearly. GROW, BOUNCE and REWIND read but weaker. BURN reads from flame edges. GROW reads from width and the pair comparison, not from height.

## Batch 2 - 08 reruns items 1-3

### material_resource
- Path: `docs/art/actors/material_resource/references/material_resource_wave4_sheet.png`
- sha256: `0f64cb483458a31e659ac55e9a274c4fd1e3ca4959634cbd22d212a288aa1db9`
- Prompt/build: 3144x2108. Panels: resting cluster | shed-on-Impact | airborne | absorption full figure | absorption close-up. Prompts: "living Material resource at rest: small loose cluster of soft glossy translucent pearl-white substrate droplets ... same material as the Subject body ... never granular, no eyes, not organs"; "Subject recoiling from a soft impact by a grey padded block, a burst of soft glossy pearl-white droplets is shed and flies outward ... bloodless"; "three droplets flying in a gentle arc, elongated along travel, dotted arc path"; "droplet touches its foot and flows into it through a smooth liquid bridge, half merged, soft glow at the join" (ref: neutral Subject turnaround + the resting gen).
- Flaws: Material colour taken as the Subject pearl-white substrate (old sheet used cyan; no canon colour found, GLOSSARY says Material is the same substrate). Absorption close-up (bottom right) is cropped at the waist, no full silhouette; full-figure absorption (bottom left) has the merging droplet looking a little like a third foot. Shed panel: the impactor block reads as a backpack. No capsule scale panel (droplets are about fist size relative to the 1.0 m Subject in panels 2/4).

### scale_and_detail_lineup
- Path: `docs/art/shared/scale_and_detail_lineup/references/scale_and_detail_lineup_wave4_sheet.png`
- sha256: `6367f489c266218dfee73b1d8aeaee15ed563e4562f13cd0e8a36fd006c6b891`
- Prompt/build: 4030x1540. PIL true-scale composite at 110 px/m on one floor line with 1 m ticks: Subject 1.0 m (neutral production turnaround front), Researcher 1.8 m (production sheet front), Residual 1.0 m (production sheet front), 4 m shutter door 5.0 m overall (shutter_4m production, closed), barrier 1.2 m (new gen: "orthographic front elevation of a modular facility safety barrier, 2 m wide 1.2 m high, warm off-white composite, equipment-grey frame, charcoal plinth, one cyan strip", ref material board), kit bay 4 m wide x 4.6 m (new gen: "single 4 m wide wall module of large warm off-white rounded panels in equipment-grey frame, charcoal utility strip, one cyan indicator"), Material Dispenser 2.0 m (approved turnaround front), Elevated dispensing armature 12 m (wave-3 front). Framed magnified inset top-left of the small items (Subject, Researcher, Residual, barrier, dispenser) at a common enlarged scale.
- Flaws: Collage of existing production renders, so lighting and render style vary slightly between items. Residual is assumed to be 1.0 m and Researcher 1.8 m (neither is a canon number). Door scaled to 5.0 m overall frame height, so the opening is ~4 m wide x ~4.3 m, just under the 4.5 m clear contract. Kit bay height follows the gen aspect, not a 6 m spec. Soft contact shadows on cutouts are partial, and the Subject and Residual cutouts keep a thin band of their original floor shadow. The inset is not true scale against the main row.

### facility_state_language
- Path: `docs/art/shared/facility_state_language/references/facility_state_language_wave4_sheet.png`
- sha256: `32b2bacaefe95f66cf2f6fcf158d562a474bd83537b6af7d338d1cfa0dcbdb09`
- Prompt/build: 3144x1596. Same bay, same camera: normal | staging | danger / success | power-loss | Collapse. Base gen: "controlled reference render of one research-facility corridor bay, NORMAL state, fixed frontal one-point camera: off-white panels, grey floor, cylindrical machine left, slim status pylon with circle icon, 4 m door with shutter raised, linear ceiling light, floor landing square, indicators systems cyan". Each other state was an edit of that render: staging = amber, chevron icon, inward chevrons on floor, shutter half down, amber beacon; danger = coral, warning-triangle icon, hazard stripes and triangle, shutter shut, machine iris closed; success = green, tick icon, tick on floor, door open, droplet in the machine lip; power-loss = ceiling light off, floor emergency strips only, indicators dark, blank icon, dashed unlit square, shutter stuck; Collapse = wall breach into service cavity, torn shutter, X icon and X floor mark, coral indicators, machine ring offline.
- Flaws: The danger and Collapse states both use coral. They are told apart by geometry (closed shutter vs breach and torn shutter) and by icon (triangle vs X). The Collapse breach includes some sharp broken-panel debris. The motion cue (beacon rotation) can only be implied in a still. The camera is not perfectly locked: there is a small framing drift between panels.

## Batch 3 - 08 reruns items 4-5

### subject_physical_states
- Path: `docs/art/actors/subject_physical_states/references/subject_physical_states_wave4_sheet.png`
- sha256: `a51f9410520c8e48567b066b2fdbc46d6f6f1856822b19a02b0b9f6f3fe3dc2c`
- Prompt/build: 3144x2901. Row 1 (one gen, 5 keys): idle | move | jump | land | basic Impact. Row 2: Stability Loss (crop of strip B) | Critical Stability (own gen) | Destabilisation (crop of strip B) | Drop + Recall (own gen). Prompts: "animation key-pose strip of the exact same Subject ... five full-body poses in one row, same scale, same floor line: IDLE / MOVE / JUMP airborne / LAND squashed / BASIC IMPACT short punch ... no Verb colours"; "CRITICAL STABILITY: still standing but losing form, head tip drooping, body sagging like softening jelly, coat sliding, feet spreading"; strip B "STABILITY LOSS recoil shedding one droplet ... DESTABILISATION collapsed into a soft glossy puddle with the coat on top, bloodless"; "DROP: open-air free fall well below a short ceiling tube, clear gap ... RECALL: reversed suction pulls it UP into the tube, head tip inside, body stretched thin". Ref: neutral production turnaround.
- Flaws: Side-3/4 keys, not orthographic. The land key looks like a crouch rather than a touchdown squash. Basic Impact is a weak punch. The Drop/Recall tubes are generic grey cylinders, not the Dispensing Line pipette or the Drop/Recall socket design. Row 2 crops have a faint panel seam around the Destabilisation crop. The Stability Loss shed droplet is small.

### residual_adverb_overlay
- Path: `docs/art/actors/residual_adverb_overlay/references/residual_adverb_overlay_wave4_sheet.png`
- sha256: `28cc8a77f1e98d6a2e5b522b685cfac0c7cf60e186753f060cce100647e0d7ba`
- Prompt/build: 2904x2108. Row 1: Adverb overlay turnaround front/side/3/4 | Adverb action (stuttering lunge). Row 2: neutral Residual (production sheet crop, for comparison) | Residual with assumed BURN + Adverb layered | Subject REWIND (wave-4 06 gen, for contrast). Prompts: "exact worn Residual ... unsanctioned ADVERB overlay as a glitch-like stutter: silhouette sliced into four thin horizontal bands, each shifted sideways out of alignment like a skipped frame frozen in a physical object; a faint offset duplicate silhouette lags out of step on one side only ... desaturated greys only, no glowing colour, no icons, no fire/ice/rings/ribbons"; action "jerky stuttering lunge, broken dash stutter marks"; layering "has ALSO assumed BURN ... flames follow the shifted slices, so the Verb stays recognisable while the stutter is a separate layer". Refs: residual production sheet; adverb turnaround; BURN turnaround.
- Flaws: The lagging duplicate silhouette in the turnaround is close to the REWIND "positional echo" idea. It is told apart only by being grey, single, one-sided and sliced, which is why the REWIND contrast panel is included; Bench may want the duplicate dropped. The slice gaps render as flat white bars that read as a graphic effect, not a physical material. A first try (bandage-like charcoal wraps) was rejected because it read as a mummy costume.

## Batch 4: 08 item 6 (compound kits), 0 credits (built-in GenerateImage + PIL)
Build: `/workspace/w4/free/build06c.py`. Rows stacked full width. Baked caption text was cropped off spine_b, dome_a and radial_a (the gens drew label rows despite "no text").

### separator_spine_service_route
- Path: `docs/art/compound/separator_spine_service_route/references/separator_spine_service_route_wave4_sheet.png` (3144x4889)
- sha256: `4036c3ff460774a0816f9d70b4d31bcd7dfe58828999c989d4cb6dc40fc53e1b`
- Rows: core junction (round core room with sealed hatch) + perimeter T-junction | 4 bays (core-end hatch, plain, duct walls, observation window) | 4 states (utility wall, sealed shutter, open route with cyan chevrons, breached route).
- Prompts: "straight 4 m wide thick-walled service corridor ... open-top cutaway, isometric three-quarter top-down ... warm off-white rounded walls, cool grey floor, thin cyan indicators, no text". The junction prompt used the spine_b gen as its style reference.
- Flaws: The core junction is drawn as a small round room, not a section of the large central-core wall. The perimeter T is straight, not a curved ring. The first bay in row 2 shows a cylinder end that reads more like a tank than a core hatch. The breached-route rubble is sharp-edged. The corridor bays are not shown at a 4 m true scale.

### perimeter_maintenance_route
- Path: `docs/art/compound/perimeter_maintenance_route/references/perimeter_maintenance_route_wave4_sheet.png` (3144x3542)
- sha256: `b5bef14f91795271109e9331ba71a58747c271c8b6bd88a014e08da46fb15567`
- Rows: hero curved ring route with rail, wall plaques and doors | 4 curved modules (door frame, storage, wayfinding chevrons, damaged with coral strips).
- Flaws: The wall plaques carry small arrow and glyph marks (icon-like, not text). The modules are hook-shaped stubs, not clean arc segments. The damaged module has sharp debris.

### dome_shell
- Path: `docs/art/compound/dome_shell/references/dome_shell_wave4_sheet.png` (3144x3010)
- sha256: `843033be8b6d51c9d46fd1c5e4be7f106f6556f43e56bae887acb1969c22db64`
- Rows: faceted geodesic hemisphere on a hex slab, with a wedge cutaway (apex service ring, core column, ring deck, ribs) | kit pieces (shell bay, structural rib, apex service ring, interior treatment).
- Flaws: The radial wall spines dividing the territories are barely visible in the cutaway. The "shell bay" piece is a mini dome, not a single panel bay. The hero view's dome_b v1 had a moss patch and was replaced by v2 (no moss).

### radial_annular_kit
- Path: `docs/art/compound/radial_annular_kit/references/radial_annular_kit_wave4_sheet.png` (3144x3022)
- sha256: `608fddff077d26b2dcd54966c53b001097bea2e1e40db43ea7367d46f21aec60`
- Rows: radial floor wedge, annular floor, curved rail, core junction | perimeter junction (wall with portal) and dome interface (wall with sloped shell base).
- Flaws: The radial wedge is a straight-edged triangle, with no arc on its outer edge. The pieces are not at a shared true scale. The portal opening shows bare background, not a corridor.

## Batch 5: 08 item 7 (competitive_stress), 0 credits
Build: `/workspace/w4/free/build07.py`. Refs: the facility material board plus the old `docs/art/reference_sheets/competitive_stress/<id>.png` (content only). Old sheets were dark on dark grey; these are relit on the light board palette.

### reinforced_impact_crucible
- Path: `docs/art/competitive_stress/reinforced_impact_crucible/references/reinforced_impact_crucible_wave4_sheet.png` (3144x2925)
- sha256: `edff38bc4234bd52c30a1d8a9f228b22d6606017d69fe1294e473403588875a6`
- Rows: hero 3/4 view + plan + straight/corner barrier modules | pristine (cyan) / stressed (amber) / breached (coral, gap) / destroyed (toppled, unlit, dust).
- Prompt: "REINFORCED IMPACT CRUCIBLE ... round arena about 14 m across ringed by thick impact-resistant barrier modules ... two opposite ramp entrances, floor measurement ring of thin cyan concentric lines"; states prompt "exact same crucible ... PRISTINE / STRESSED amber / BREACHED one module knocked out, coral / DESTROYED toppled, dark".
- Flaws: The hero layout closely copies the old sheet's design. The plan view shows an octagon while the hero is near-circular. The states row is small, its letterbox bars were cropped off, and its framing is slightly soft. The breached debris is small, blunt chunks. There is no explicit scale figure.

### measurement_pylons
- Path: `docs/art/competitive_stress/measurement_pylons/references/measurement_pylons_wave4_sheet.png` (3144x3542)
- sha256: `70faf0d62d82fcc72573ceb85b2db4c2f941f70de4565e2b064900490e29f362`
- Rows: 4 views (front/side/back/3/4) | idle (arm retracted, cyan) / live (arm extended) / resolve (amber crown).
- Flaws: The four views are barely distinct; side and back read as near-front, and the probe arm moves side to side. The idle and live bar meters both look full, so only the arm length and crown colour separate the states. Displacement, dominance and resilience indicators are not clearly differentiated. There is no scale figure.

### force_plate_launch_measurement
- Path: `docs/art/competitive_stress/force_plate_launch_measurement/references/force_plate_launch_measurement_wave4_sheet.png` (2448x1848)
- sha256: `8010313d9d1ed2cffb734405f54af10fe29536fe227363b95c6711f0e1d17328`
- Panels: plate at rest | plate pressed (travel collar) | housing cutaway (spring/piston) | launch-height gauge | gauge + plate linked | neutral Subject launched, gauge lit to its height.
- Flaws: The background is mid-grey, darker than the other wave-4 sheets. The layout closely copies the old sheet. The cutaway housing looks off-white, unlike the dark plate rim. The launched Subject is large relative to the 2 m plate. There is no visible floor conduit between plate and gauge.

### shelters_test_barricades
- Path: `docs/art/competitive_stress/shelters_test_barricades/references/shelters_test_barricades_wave4_sheet.png` (3144x3542)
- sha256: `e8e65b42356f78fdefe7e0b572727b8225f0e87dc1ed50a0e7ff4f5011ad08cb`
- Rows: pristine shelter/deflector/barricade + damaged row | open layout on a test floor with two neutral Subjects for scale.
- Flaws: The v1 gen had baked text captions and was rerun (v2, no text). The props are each shown in one view only, not front plus 3/4. The damaged shelter keeps its cyan indicators. The layout is dense and semi-gridded; it avoids lanes, but there are too many props. Some "pristine" props in the layout carry coral strips.

## Batch 6: 08 item 8 (adaptive_containment), 0 credits
Build: `/workspace/w4/free/build08c.py`. Refs: material board, old `docs/art/reference_sheets/adaptive_containment/<id>.png` (content only), and the Residual production sheet (the old sheets used a blue figure; this batch uses the canon pale Residual and the neutral Subject). Restrained: no gore, no slime, no fire.

### specimen_delivery_column
- Path: `docs/art/adaptive_containment/specimen_delivery_column/references/specimen_delivery_column_wave4_sheet.png` (3144x3542)
- sha256: `4a7029e154e80804de2fffe8a14aae685339711f1d343de3c454b09225262d47`
- Rows: front/side/back/3/4 turnaround (~6 m column: restraint clamps, intake/release hatch, glazed chamber, ceiling intake head) | idle / live (Residual held inside) / release (hatch open, amber) / failure (cracked glass, coral).
- Flaws: The states row mixes views (states 3 and 4 copy the back and 3/4 views), so it is not a single camera. The Residual reads blue-tinted from the cyan chamber light. Release and failure look alike: both have the hatch open. There is no scale figure outside the column.

### perimeter_pens_shutters
- Path: `docs/art/adaptive_containment/perimeter_pens_shutters/references/perimeter_pens_shutters_wave4_sheet.png` (2448x1398)
- sha256: `44dcf506212fd8f55693e6d86be4f1d3a854dbaff89746f436364d7ec5941ea9`
- Panels: closed (inspection window, feed hatch) | open | jammed | interior cutaway 3/4 | closed bay with Residual for scale.
- Flaws: The jammed shutter is drawn as a hinged panel swung off, not a roller shutter stuck half-open. The scale panel's bay has a different front (side door, no window). The Residual looks too large against the bay (it should be ~1 m). The sheet is a single 16:9 gen, upscaled.

### vents_wall_cavities
- Path: `docs/art/adaptive_containment/vents_wall_cavities/references/vents_wall_cavities_wave4_sheet.png` (2448x1848)
- sha256: `f6a9ad0bbc98a06e9ebc3ef3059e4c9a71316cdaa29280ade38fc7cc7e14bf2f`
- Panels: standard vent | torn vent | wall aperture | service cavity interior | Residual emerging | Residual stepped out.
- Flaws: The clean-cut aperture (panel 3) does not match the torn edges in panels 4–6. The emergence panels read as standing in the opening, not climbing out. The Residual is large against the aperture. The layout follows the old sheet closely.

### bait_machinery
- Path: `docs/art/adaptive_containment/bait_machinery/references/bait_machinery_wave4_sheet.png` (2448x1285)
- sha256: `b6edc1ea6acbc84a3478efbf58dd3524af943929d90dd308dc6ee78919fe3452`
- Rows: front/side/back/3/4 (reservoir, delivery arm, floor lure plate, service socket) | idle / delivering / spent / service (cartridge out).
- Flaws: The gen baked state captions, so the caption row was cropped off; this clips the bottom edge of the bottom-row floor plates. Idle and delivering look alike (the arm is extended in both). The front view is missing the arm. The design follows the old sheet closely.

### defensive_power_node
- Path: `docs/art/adaptive_containment/defensive_power_node/references/defensive_power_node_wave4_sheet.png` (2448x1398)
- sha256: `f3657e2431fbb25c7ab8778e6b5317197520050be66d614d79089e81742d2253`
- Rows: front/side/3/4/plan of the guarded node with clearance ring | powered (with neutral Subject for scale) / unpowered / overloaded (guards opened, coral).
- Flaws: The top row shows a fully closed housing, but the states row shows an open-ribbed housing; the design is inconsistent, and the closed form can be read as "sealed guard". v1 had gibberish baked text and a black Subject, so it was rerun (v2, no text). The front, side and 3/4 views are near-identical.
