# 3D Reference Asset Map

This document records the current visual-reference coverage for the complete VerbEndings 3D asset portfolio. It complements the spatial and visual contracts in [`WORLD_DESIGN.md`](../WORLD_DESIGN.md) and the production boundary in [`VISUAL_ASSET_PIPELINE.md`](../VISUAL_ASSET_PIPELINE.md).

## Evidence Classes

- **Integrated Production** — an asset is instantiated in Godot behind its documented gameplay boundary and has retained source, export, renders, and validation evidence.
- **Production Source** — retained project-owned evidence is suitable to drive authored reconstruction or retopology, but is not a runtime export.
- **Context Reference** — evidence establishes mood, scale, composition, motion, or material language only. It is not suitable for direct reconstruction without a canonical asset sheet.
- **Greybox Contract** — dimensions, collision, spatial relationships, and behaviour exist in Godot, but production visual evidence is absent.
- **Uncovered** — neither an approved production source nor a focused canonical reference package exists.

These evidence classes are separate from the Greybox, Proxy, Production, and Polish runtime-readiness levels defined by the visual asset pipeline.

## Wiki machine index

[`wiki_catalog.json`](wiki_catalog.json) mirrors the family rows below for the static wiki build (`tools/wiki/generate.py`). Evidence wording in this document remains authoritative; the JSON only adds paths and ids. See [`WIKI_CATALOG.md`](WIKI_CATALOG.md).

## Generated Sheet Coverage

[`reference_sheets/`](reference_sheets/) contains 47 generated focused sheets. Together with the existing shared Subject turnaround, the package provides visual-development coverage for all 48 asset-family rows below. The generated sheets are candidate modelling and review inputs: they do not change an evidence class until a focused asset review accepts the relevant geometry, scale, origin, material boundaries, collision ownership, and runtime target. The evidence classifications and remaining canonical requirements below therefore continue to describe the approved project state.

The suite index, use boundary, prompt set, and generation record are retained in [`reference_sheets/README.md`](reference_sheets/README.md), [`reference_sheets/PROMPTS.md`](reference_sheets/PROMPTS.md), and [`reference_sheets/PROVENANCE.md`](reference_sheets/PROVENANCE.md).

## Canonical Reference Package

Every focused static-prop package contains:

- one consistent object shown front, left, back, and front three-quarter;
- orthographic primary views, neutral studio lighting, complete silhouettes, and visible floor contact;
- no labels, loose VFX, extra objects, grid contamination, or geometry that should not be reconstructed;
- a written metre-scale envelope, contact origin, facing direction, material boundaries, collision owner, and runtime target; and
- additional sheets for any authored physical state whose geometry or collision changes.

Actor packages also contain a neutral shared-identity turnaround, semantic surface separation, a rig pose, key deformation checks, and scale comparison against the gameplay capsule. Environment packages contain a canonical plan and section, one third-person gameplay-camera key view, a modular-kit sheet, and state coverage. Context references never substitute for these packages.

## Shared Visual Language

| Asset family | Current evidence | Missing canonical evidence |
| --- | --- | --- |
| Facility form and material language | Partial. The Material Dispenser is Integrated Production; the FLUX intro is Context Reference. | A neutral material board covering warm off-white panels, cool floors, equipment grey, charcoal recesses, near-black service spaces, glazing, rubber, painted composite, rough metal, and bounded emissions. |
| Facility lighting and state language | Written contract and greybox hooks only. | Controlled normal, staging, danger, success, power-loss, and Collapse views with geometry, icon, and motion cues alongside colour. |
| Scale and detail density | Partial Subject, Material Dispenser, and video context. | One shared lineup containing a Subject, Researcher, Residual, 4 m door, barrier, kit bay, dispenser, and dominant Laboratory apparatus. |
| Semantic Engine interfaces | Video Context Reference only. | Physical panel, printer, indicator, and machinery families with no avatar, face, or floating conversational persona. |

## Actors And Living Material

| Asset family | Current evidence | Missing canonical evidence |
| --- | --- | --- |
| Shared Subject | **Context Reference.** Four project-owned turnarounds and Meshy input crops establish intended anatomy. Wrong-design Meshy concept GLBs were pruned (2026-10-23). | Approved concept mesh (or authored reconstruction); separate body, eyes, suit, and identity surfaces; neutral default presentation; floor-contact origin; exact scale; rig; deformation evidence; semantic animation clips; runtime GLB. |
| Subject identity | Partial within the shared Subject sheets. | Stable suit-number treatment and replaceable identity panel that remain independent from any claimed Verb. Generated `SAD SHIELD` text, barcode detail, and permanent Verb colour are excluded. |
| Subject Verb Effects | Written per-Verb colour, silhouette, icon, and motion contract only. | One treatment sheet for each of BURN, SHIELD, GROW, STRETCH, ROLL, JUMP, BOUNCE, FREEZE, and REWIND, shown on the same neutral Subject and readable without colour alone. |
| Subject physical states | Greybox animation hooks only. | Idle, movement, jump, landing, basic Impact, Stability Loss, Critical Stability, Destabilisation, Drop, and Recall deformation keys. |
| Researcher | FLUX intro Context Reference only. | Canonical turnaround, face and hair sheet, hands and practical clothing details, scale view, booth performance poses, and clumsy physical-comedy keys. |
| Residual | Greybox Contract only. | Neutral turnaround derived from shared Droplet ancestry without copying stable Subject identity; garment/disposal evidence; deforming topology; assumed-Verb compatibility. |
| Residual Adverb overlay | Runtime hook and written behaviour contract only. | Separate material and motion grammar for unsanctioned Adverbs that cannot be mistaken for a tenth Verb. |
| Material resource | Greybox Contract only. | Resting, shed-on-Impact, airborne, and absorption forms with a readable soft-substrate silhouette and no resemblance to ordinary rendering material. |

## Compound And Reusable Environment Kit

| Asset family | Current evidence | Missing canonical evidence |
| --- | --- | --- |
| Complete Compound | Greybox Contract only. | Canonical hexagonal-plan and section sheet showing the faceted hemisphere, three nominal 120-degree Laboratory territories, non-zero-width Separator Spines, Central Core, Assignment Deck, perimeter route, and Collapse connections. |
| Central Core | FLUX intro Context Reference and greybox dimensions. | Exterior machinery turnaround, base and upper-service details, Assignment Deck relationship, dangerous Collapse shortcuts, and normal/offline states. |
| Assignment Deck | FLUX intro Context Reference and greybox annulus. | Third-person key view plus annular floor, inner and outer rails, Laboratory sightline fascia, Brief/Result machinery, and inaccessible Collapse state. |
| Researcher booth | Small elevated Researcher context in the FLUX intro; reserved greybox footprint. | A physically docked booth or rail-mounted work platform that preserves Laboratory sightlines without creating an extra occupied facility tier. |
| Separator Spine and Service Route | Greybox Contract only. | Core junction, perimeter junction, corridor bay, observation window, utility wall, sealed shutter, open route, and breach variants. |
| Perimeter maintenance route | Greybox Contract only. | Annular route segment, Laboratory connection, utility clutter, dependable navigation cues, and damaged Collapse state. |
| Dome shell | Greybox Contract only. | Faceted shell bay, structural rib, apex service ring, inner acoustic/utility treatment, and exterior cutaway. |
| Orthogonal kit | Greybox Contract only. | Floor bay, wall bay, utility wall, 4 m door frame, 4 m shutter, column, truss, vent, panel, barrier, and observation-window atlas at 1 m and 2 m increments. |
| Radial and annular kit | Greybox Contract only. | Radial floor, annular floor, rail, Core junction, perimeter junction, and dome-interface atlas for the bounded specialised subset. |
| Dispensing Line | Greybox Contract only. The FLUX Subject-forming nozzle is a different machine. | Overhead carrier, adjacent Subject tubes, rail junctions, Laboratory branch, Release opening, flexible pressure tube, and normal/offline state. |
| Drop and Recall infrastructure | Greybox Contract only. | Tube exit, Drop-time silhouette, Laboratory ceiling socket, floor collection aperture, reversed-pressure Recall state, and 24-Subject layout evidence. |

## Applied Attrition Laboratory

| Asset family | Current evidence | Missing canonical evidence |
| --- | --- | --- |
| Laboratory composition | Greybox Contract only. | Plan, section, Drop key view, player-camera view, three Landing strategies, elevated supply silhouette, broad circulation, and sightline to the Assignment Deck. |
| Elevated dispensing armature | Greybox Contract only. | Support column, dispensing truss, elevated Material supply, access interfaces, and authored pristine/stressed/breached/destroyed states. |
| Material Dispenser | **Integrated Production.** Approved turnaround, Blender source, runtime GLB, controlled renders, and evidence are retained. | No base-form evidence is missing. Shutter and power-state evidence is absent; any such state remains subordinate to the existing dimensions and socket. |
| Breakable Material housing | Greybox Contract only. | Closed, stressed, breached, and broken states; internal Material containment; release socket; clear damage-focused Verb affordance. |
| Counterweight Plate | Greybox Contract only. | Plate, mass crates, threshold mechanism, loaded/unloaded states, and large-scale force relationships. |
| Wrecking Pendulum | Greybox Contract only. | Support frame, pin joint, heavy bob, target wall, safe arc, and wide-swing state. |
| Gravity Funnel | Greybox Contract only. | Catch basin, loose balls, rim/bank surfaces, intake state, and readable attraction field hardware. |
| Domino Tower | Greybox Contract only. | Stable stacked blocks, crown, weakened base, partially fallen state, and fully toppled state. |
| Momentum Turbine | Greybox Contract only. | Rotor, protected hub, bearing housing, interaction faces, direction cue, and spinning state. |

## Competitive Stress Laboratory

| Asset family | Current evidence | Missing canonical evidence |
| --- | --- | --- |
| Laboratory composition | Greybox Contract only. | Plan, section, Drop key view, player-camera view, three Landing strategies, open central contest space, shelters, and broad circulation. |
| Reinforced impact crucible | Greybox Contract only. | Dominance boundary, impact-resistant barrier family, floor measurement ring, entrances, and authored state variants. |
| Measurement pylons | Greybox Contract only. | Four-view prop sheet with displacement, dominance, and resilience physical indicators; idle/live/resolve states. |
| Force plates and launch measurement | Written contract only. | Plate family, mechanical travel indicator, launch-height gauge, and readable cause-to-measurement relationships. |
| Shelters and test barricades | Greybox barriers only. | Low shelter, angled deflector, movable test barricade, damaged state, and layouts that do not form hard lanes. |

## Adaptive Containment Laboratory

| Asset family | Current evidence | Missing canonical evidence |
| --- | --- | --- |
| Laboratory composition | Greybox Contract only. | Plan, section, Drop key view, player-camera view, three Landing strategies, containment perimeter, and physical hostile-entry paths. |
| Specimen-delivery column | Greybox Contract only. | Column turnaround, intake and release machinery, restraint interfaces, idle/live/failure states, and authored structural thresholds. |
| Perimeter pens and shutters | Written contract only. | Modular pen bay, inspection window, feed hatch, closed/open/jammed shutter states, and Residual-scale comparison. |
| Vents and wall cavities | Greybox vent hooks only. | Standard vent, torn vent, wall aperture, service-cavity interior, and physical emergence sequence. |
| Bait machinery | Written contract only. | Reservoir, delivery arm, floor lure, spent state, and service connection. |
| Defensive power node | Written contract only. | Protected node, conduits, powered/unpowered/overloaded states, and interaction clearance. |
| Residual nests and concealed evidence | Narrative contract only. | Bloodless nests, obsolete equipment, discarded identity bands, hidden routes, and disposal evidence using restrained environmental horror. |

## Facility State And The Collapse

| Asset family | Current evidence | Missing canonical evidence |
| --- | --- | --- |
| Shared structural state | Runtime ledger and Greybox Contract. | Clean, stressed, and breached surface variants that preserve wall/floor collision and navigation. |
| Authored prop thresholds | Runtime ledger and named thresholds. | Pristine, stressed, breached, and destroyed sheets for each dominant Laboratory apparatus, with explicit collision-changing parts. |
| Event overlays | Runtime state hooks. | Machinery, power, containment, and environmental overlay examples that never visually repair or contradict persistent state. |
| Complete Collapse Compound | Implemented greybox lifecycle and routes. | Damaged full-Compound key view, sealed Assignment Deck, open Separator and perimeter routes, dangerous Core shortcuts, offline cyan systems, coral failure telegraphs, and contracting safe-space compositions. |

## Retained Source Disposition

Shared Subject concept GLBs and their controlled renders were pruned as wrong design. Retained turnarounds and `meshy_inputs/` are Context Reference only. `Player.tscn` still uses greybox presentation. A future concept mesh needs Benjamin’s ask-before-paid Meshy gate.

The third-pass FLUX intro is Context Reference. Its Compound mass, elevated Researcher context, Semantic Engine machinery, generated motion, and synchronised audio are useful; its dark detail density, adjacent coloured outlets, and permanently Verb-coloured Subject presentation are not canonical asset specifications.
