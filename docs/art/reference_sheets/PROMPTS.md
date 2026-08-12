# Final Reference-Sheet Prompt Set

This document records the compositional prompt set for the 47 retained PNG outputs in this directory. For each output, the generation request combines the common request, the relevant reference assignment, the family-specific delta, and the retained-output constraints. The written project contracts remain authoritative where an image is ambiguous.

## Common Request

```text
Create one professional stylised 3D asset reference sheet for VerbEndings.

Use case: stylized-concept for a new sheet, or precise-object-edit when enforcing a retained-output constraint.
Asset type: the named character, prop, modular environment family, composition, or facility-state family.
Reference use: preserve only the shape language, palette, material response, anatomy, or spatial relationship explicitly assigned to the family. Do not copy incidental text, labels, barcodes, logos, or non-canonical geometry.
Style: rounded simplified stylised PBR; clinical, buoyant, tactile, overconfident, and quietly uncanny; warm off-white composite panels; cool grey floors; equipment grey; charcoal recesses; near-black service spaces; sparse cyan system light; coral only for danger; restrained moss accent; soft-substrate living Material.
Presentation: neutral studio or controlled facility context; clean cells; complete silhouettes; visible floor contact; legible part separation; consistent scale; practical construction; large readable physical relationships; no cropped geometry.
Lighting: soft neutral key and fill with restrained contact shadows; no cinematic darkness, bloom wash, dramatic colour cast, or atmospheric obstruction.
Constraints: no captions, callouts, arrows, dimensions, rulers, grids, UI, watermark, signature, floating conversational persona, face-like machinery, decorative holograms, or loose VFX. Exclude generated labels and incidental markings except for the intentional diegetic number tile in the Subject identity sheet. Keep emission bounded to small practical indicators. Show physical mechanisms rather than unexplained energy fields.
```

## Reference Assignment

- Subject-derived sheets use `subjects/shared_subject/references/subject_shield_turnaround.png` for common anatomy, garment construction, scale, and soft-substrate response. Permanent `SAD SHIELD` text, barcode detail, and Verb colour are excluded.
- Facility and equipment sheets use `material_dispenser_comparison/references/turnaround_approved.png` for hard-surface shape language, palette, roughness, panel hierarchy, and bounded emission. Its silhouette is exclusive to the Material Dispenser.
- Compound-descendant sheets use `compound/complete_compound.png` only for the canonical single-floor topology, elevated Assignment Deck annulus, and three Laboratory relationships.
- Laboratory apparatus, Residual overlay, and Collapse sheets may use their retained parent sheet for family consistency without importing extra geometry.

## Shared Visual Language

| Output | Family-specific prompt delta |
| --- | --- |
| `shared/facility_material_board.png` | A clean material-and-form board showing warm off-white composite panels, cool grey floor, equipment-grey mechanism, charcoal recess, near-black service cavity, clear glazing, dark rubber, painted composite, rough metal, cyan status emission, coral danger emission, and restrained moss accent as large unlabelled samples and simple facility parts. |
| `shared/facility_state_language.png` | One consistent facility bay in six clearly separated physical states: normal, staging, danger, success, power loss, and Collapse. Distinguish states through shutters, vanes, access position, luminaire behaviour, exposed mechanism, wear, and motion posture as well as colour. Persistent damage never repairs. |
| `shared/scale_and_detail_lineup.png` | Neutral orthographic scale lineup containing one Subject, one taller Researcher, one worn Residual, a 4 m door, waist-high barrier, orthogonal kit bay, Material Dispenser, and one dominant Laboratory apparatus. Preserve relative scale and shared detail density without measurement text. |
| `shared/semantic_engine_interfaces.png` | Atlas of physical Semantic Engine interfaces: recessed wall panel, ticket/printer output, segmented status indicator, mechanical selector, machinery console, and result/brief apparatus. All intelligence reads through industrial hardware; nothing resembles an avatar, face, floating assistant, or chat screen. |

## Actors And Living Material

| Output | Family-specific prompt delta |
| --- | --- |
| `actors/subject_identity.png` | The same neutral Subject in front, side, back, and three-quarter views, with a replaceable number tile using simple digits and a removable identity panel integrated into the suit. Identity remains independent of Verb effects; no Verb word or barcode appears. |
| `actors/subject_verb_effects.png` | Nine cells showing the same neutral Subject with distinct treatments for BURN, SHIELD, GROW, STRETCH, ROLL, JUMP, BOUNCE, FREEZE, and REWIND. Every treatment combines silhouette, physical deformation, posture, icon-like geometry, or motion trace so it remains readable without colour. Do not print the Verb names. |
| `actors/subject_physical_states.png` | Animation-key sheet for idle, movement, jump, landing, basic Impact, Stability Loss, Critical Stability, Destabilisation, Drop, and Recall. Preserve shared anatomy and garment separation while emphasising pose, compression, stretch, wear, and physical force. |
| `actors/researcher.png` | Canonical human Researcher sheet with front, side, back, and three-quarter turnaround; face, hair, practical clothing, hands, Subject scale comparison, booth-operating poses, and clumsy physical-comedy keys. The person is capable but physically fallible, with no heroic or militarised styling. |
| `actors/residual.png` | Neutral worn Residual derived from Droplet ancestry: front, side, back, and three-quarter turnaround, disposal garment evidence, softened unstable topology, identity-band remnants, deformation keys, and Subject comparison. It is neither a zombie nor a pristine Subject and has no stable identity marking. |
| `actors/residual_adverb_overlay.png` | Apply a separate unsanctioned Adverb grammar to the exact worn Residual: irregular secondary material bands, asymmetrical timing echoes, stuttering trails, and unstable local deformation. Preserve the Residual silhouette and make the overlay unmistakably different from all nine Verb treatments. |
| `actors/material_resource.png` | Show living Material as small soft-substrate resource forms in four states: resting pieces, freshly shed Impact pieces, airborne pieces, and absorption against a Subject's non-human lower body surface. Resting pieces are tactile droplets or pliable fragments, never miniature actors, organs, gore, or ordinary construction material. |

## Compound And Reusable Environment Kit

| Output | Family-specific prompt delta |
| --- | --- |
| `compound/complete_compound.png` | Canonical plan, section, exterior cutaway, and third-person key view of one hexagonal faceted hemisphere with exactly three nominal 120-degree Laboratory territories on one continuous Test Floor, non-zero-width Separator Spines, a Central Core, one elevated annular Assignment Deck, a closed perimeter route, and visible Collapse connections. The section contains no stacked Laboratory floors. |
| `compound/central_core.png` | Exterior machinery turnaround and sectional details for the Central Core, including base machinery, upper service assembly, its relationship to the elevated Assignment Deck, normal and offline physical states, and dangerous Collapse shortcut openings. |
| `compound/assignment_deck.png` | Third-person key view plus annular-kit sheet for the elevated Assignment Deck: continuous annular floor, inner and outer rails, Laboratory sightline fascia, Brief/Result machinery, Researcher operating positions, and a physically inaccessible Collapse state. It is a platform within the volume, not an occupied extra facility tier. |
| `compound/researcher_booth.png` | A compact physically docked or rail-mounted Researcher booth shown in turnaround, section, deck attachment, and operating poses. It preserves clear Laboratory sightlines and remains part of the Assignment Deck rather than becoming another floor. |
| `compound/separator_spine_service_route.png` | Modular Separator Spine and Service Route atlas with Core junction, perimeter junction, corridor bay, observation window, utility wall, sealed shutter, open route, and breached route. Use human-scale construction and preserve a non-zero-width navigable spine. |
| `compound/perimeter_maintenance_route.png` | Annular maintenance-route segment with Laboratory connection, utility clutter, dependable repeated navigation cues, intact state, and damaged Collapse state. Keep the route physically continuous and service-oriented. |
| `compound/dome_shell.png` | Faceted dome-shell construction sheet with repeatable shell bay, structural rib, apex service ring, interior acoustic/utility treatment, connection details, and exterior cutaway. The result is a hemisphere-scale kit, not a smooth glass dome. |
| `compound/orthogonal_kit.png` | Unlabelled atlas at consistent implied 1 m and 2 m increments containing floor bay, wall bay, utility wall, 4 m door frame, 4 m shutter, column, truss, vent, panel, barrier, and observation window. Parts are isolated, complete, and reconstruction-friendly. |
| `compound/radial_annular_kit.png` | Bounded specialised atlas of radial floor, annular floor, curved rail, Core junction, perimeter junction, and dome-interface pieces, including clean connection seams and matching facility materials. |
| `compound/dispensing_line.png` | Overhead Dispensing Line construction and state sheet showing carrier rail, adjacent Subject tubes, rail junction, Laboratory branch, Release opening, flexible pressure tube, and normal/offline state. Use a neutral unmarked Subject only for scale and interaction; no printed jacket identity. |
| `compound/drop_recall_infrastructure.png` | Drop and Recall sheet with tube exit, clearly physical open-air Drop silhouette, Laboratory ceiling socket, floor collection aperture, reversed-pressure Recall configuration, and one explicit arrangement of exactly three banks of eight sockets for the 24-Subject ceiling. |

## Applied Attrition

| Output | Family-specific prompt delta |
| --- | --- |
| `applied_attrition/laboratory_composition.png` | One wedge-shaped 120-degree Laboratory territory shown in plan, section, Drop key view, and player-camera view. Include three recoverable Landing strategies, elevated Material supply, broad circulation, Assignment Deck sightline, five apparatus families, and no enclosing full-Compound chamber. |
| `applied_attrition/elevated_dispensing_armature.png` | Support column, dispensing truss, elevated Material supply, access interfaces, and four physical thresholds: pristine, stressed, breached, and destroyed. Preserve route clearance below and show detached or displaced parts only where thresholds require them. |
| `applied_attrition/material_dispenser_states.png` | Preserve the approved Material Dispenser form, dimensions, front socket relationship, and material separation exactly. Show only two authored states: powered with the iris shutter physically open and restrained cyan indication, and offline with the iris shutter physically closed and emission absent. |
| `applied_attrition/breakable_material_housing.png` | A distinct low horizontal containment chest, not a Material Dispenser, shown closed, stressed, breached, and broken. Include visible internal living Material containment, a release socket, break seams, and damage-focused physical affordance. |
| `applied_attrition/counterweight_plate.png` | Large floor plate, separate mass crates, exposed threshold mechanism, unloaded state, partially loaded state, and fully loaded state. Weight and travel read through compression, linkages, and scale rather than arrows or gauges. |
| `applied_attrition/wrecking_pendulum.png` | Support frame, visible pin joint, heavy rounded bob, target wall, protected safe arc, resting state, and wide-swing state. Keep the apparatus physically plausible and traversal-scaled. |
| `applied_attrition/gravity_funnel.png` | Broad catch basin, loose balls, readable rim and bank surfaces, intake mechanism, inactive state, and active attraction hardware. Attraction is conveyed by physical machinery and ball placement, not a magical field or annotation. |
| `applied_attrition/domino_tower.png` | Large stable stack of chunky blocks with crown, weakened base, partially fallen state, and fully toppled state. Keep each threshold legible and the blocks traversal-scaled. |
| `applied_attrition/momentum_turbine.png` | Rotor, protected hub, bearing housing, robust interaction faces, physical direction cue in blade geometry, still state, and spinning state. No drawn arrows or text. |

## Competitive Stress

| Output | Family-specific prompt delta |
| --- | --- |
| `competitive_stress/laboratory_composition.png` | One 120-degree Laboratory territory in plan, section, Drop key view, and player-camera view with three Landing strategies, open central contest space, reinforced crucible, measurement pylons, force plates, shelters, and broad circulation that does not form hard lanes. |
| `competitive_stress/reinforced_impact_crucible.png` | Dominance-boundary apparatus with impact-resistant barrier family, floor measurement ring, several broad entrances, and intact, live, stressed, and resolved physical states. Preserve open player circulation. |
| `competitive_stress/measurement_pylons.png` | Four-view pylon family with mechanical indicators for displacement, dominance, and resilience plus idle, live, and resolve states. Use moving rings, shutters, plungers, or height changes instead of text and screens. |
| `competitive_stress/force_plate_launch_measurement.png` | Force-plate family with visible mechanical travel, launch-height measurement hardware, and clear physical cause-to-measurement relationships across idle, compressed, release, and peak states. |
| `competitive_stress/shelters_test_barricades.png` | Low shelter, angled deflector, movable test barricade, and damaged variants in isolated views plus a loose arena arrangement. The forms break sightlines locally without creating hard lanes or safe bunkers. |

## Adaptive Containment

| Output | Family-specific prompt delta |
| --- | --- |
| `adaptive_containment/laboratory_composition.png` | One 120-degree Laboratory territory in plan, section, Drop key view, and player-camera view with three Landing strategies, containment perimeter, delivery column, pens, vents, bait machinery, power node, concealed evidence, and several physical hostile-entry paths. |
| `adaptive_containment/specimen_delivery_column.png` | Column turnaround and sectional states showing intake machinery, release machinery, restraint interfaces, idle, live, stressed, breached, and failure thresholds. Hostile delivery remains visibly physical. |
| `adaptive_containment/perimeter_pens_shutters.png` | Modular pen bay, inspection window, feed hatch, and closed, open, and jammed shutter states with a worn Residual for scale. Containment uses thick mechanical parts and practical clearances. |
| `adaptive_containment/vents_wall_cavities.png` | Standard vent, torn vent, wall aperture, service-cavity interior, and staged physical Residual-emergence sequence. Preserve the shared wall kit and avoid gore. |
| `adaptive_containment/bait_machinery.png` | Reservoir, articulated delivery arm, floor lure, spent state, service connection, and operating clearances. Bait is biological-looking living Material handled by clinical machinery, without gore. |
| `adaptive_containment/defensive_power_node.png` | Protected power node, conduits, clear interaction space, and powered, unpowered, overloaded, and physically damaged states. Use shielding, shutters, insulators, and restrained practical emission rather than text or lightning decoration. |
| `adaptive_containment/residual_nests_concealed_evidence.png` | Bloodless environmental-horror sheet with Residual nests, obsolete equipment, discarded identity bands, concealed route apertures, and disposal evidence. Keep clues small but physically reconstructable and avoid corpses or gore. |

## Facility State And Collapse

| Output | Family-specific prompt delta |
| --- | --- |
| `facility_state/shared_structural_state.png` | The same wall, floor, door, rail, and utility surfaces in clean, stressed, and breached variants. Preserve the primary collision envelope and navigable floor while damage accumulates through displaced panels, cracks, exposed structure, and debris pockets. |
| `facility_state/authored_prop_thresholds.png` | Dominant apparatus families from all three Laboratories shown at pristine, stressed, breached, and destroyed thresholds. Make collision-changing parts visually explicit and keep each apparatus recognisable across thresholds. |
| `facility_state/event_overlays.png` | Compatible machinery, power, containment, and environmental overlay examples applied over already worn facility states. Use physical shutters, warning vanes, open access, stopped machinery, power changes, and restrained haze; overlays never repair persistent damage or create energy walls. |
| `facility_state/complete_collapse_compound.png` | Damaged full-Compound plan, section, exterior cutaway, and player-camera key view preserving the three-Laboratory topology. Seal the Assignment Deck, open Separator and perimeter routes, expose dangerous Core shortcuts, reduce cyan systems, use coral failure telegraphs, and show contracting safe-space composition without making routes unreadable. |

## Retained-Output Constraints

The following constraints apply to the final files even where a family delta is silent:

- The Complete Compound contains one continuous Test Floor and one elevated annular Assignment Deck, never stacked Laboratories.
- Applied Attrition composition shows one Laboratory wedge, not an entire chamber.
- Drop is an open-air physical fall from a tube, and the socket overview contains exactly 24 positions arranged as three groups of eight.
- The Adverb overlay is applied to the worn Residual, not a pristine Subject.
- Material pieces never resemble miniature people or human anatomy.
- The breakable Material housing remains visually distinct from the Material Dispenser.
- Material Dispenser state coverage changes only shutter position and power indication; its approved base form remains fixed.
- Event overlays use physical machinery and state changes, not forcefields or decorative energy walls.
- Reconstruction inputs contain no generated captions, measurement labels, arrows, Verb jacket text, barcodes, or logos; the Subject identity sheet retains its intentional diegetic number tile.
