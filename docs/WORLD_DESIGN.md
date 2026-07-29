# World And Visual Design

[`CONTEXT.md`](../CONTEXT.md) defines the domain language and Trial rules. This document defines the durable spatial, visual, narrative, and production contracts for the Compound.

## Creative Direction

VerbEndings is **clinical, buoyant, tactile, overconfident, and quietly uncanny**. Friendly physical comedy sits inside an industrial research facility that treats language and living Subjects as measurable inputs.

The visual style is stylised PBR: rounded, simplified forms with believable material response, mass, lighting, and contact. Physics supplies play and humour. Horror remains implied and bloodless, emerging through classification labels, obsolete equipment, discarded identity bands, hidden nests, and the facility's routine treatment of failed Droplets.

The Semantic Engine communicates through plans, panels, lights, printers, and machinery. It has no avatar or conversational persona. The Researcher is the sole regular speaking character: sincere, subordinate to the Engine, physically clumsy, and careless enough to reveal what the institution conceals.

## Compound Topology

The Compound is a faceted hemisphere with a hexagonal plan around a vertical Central Core. Its main floor is organised as three repeating nominal 120-degree territories. Each territory contains one wedge-shaped Laboratory and shares the separator structures on its two radial boundaries; the Laboratories never meet along a zero-width line.

Thick, non-zero-width radial separator spines sit between neighbouring Laboratories. They belong to the Compound rather than either Test Floor and contain service corridors, observation rooms, utilities, shutters, concealed connections, and other facility machinery. A repeating planning cell therefore reads as half a separator spine, one Laboratory, and half a separator spine. A perimeter maintenance route provides a longer connection between Laboratories.

An elevated annular Assignment Deck surrounds the Core. It hosts Verb Selection, Pair Drafts, Experiment Briefs, Result Announcements, and the Researcher's booth. The Dispensing Line runs from this deck along ceiling rails to each Laboratory.

Normal Rounds confine Subjects to the active Laboratory and keep separator service routes sealed from the Test Floor. Previously used Laboratories remain visible and retain authored state. During the Collapse, separator routes, the perimeter route, and dangerous Core shortcuts connect the complete Compound; the Assignment Deck is inaccessible.

The primary partition is three repeating 120-degree planning cells aligned to the hexagonal plan. Smaller 15- or 30-degree radial modules may structure specialised details inside that envelope, but they do not define Laboratory boundaries. Test Floors and most apparatus use a 2 m orthogonal planning grid with 1 m detail increments. Provisional Laboratory spans are 48–56 m, measured independently of separator-spine and service-route width, and must accommodate 8–12 Subjects comfortably while preserving a viable path to 24-Subject validation.

## Laboratories

### Applied Causality Laboratory

This Laboratory tests whether Verbs can make physical systems produce useful results. A raised result receiver is its dominant silhouette. Apparatus covers momentum transfer, counterweights, trajectory, gravity, and linked machine chains. Cause, transfer, and outcome read through geometry and motion rather than small labels.

### Competitive Stress Laboratory

This Laboratory measures dominance, displacement, and resilience. A reinforced impact crucible and measurement pylons dominate the space. Force plates, launch measurement, shelters, and test barricades create positional choices without turning the floor into hard lanes or sub-rooms.

### Adaptive Containment Laboratory

This Laboratory tests survival against contained Creatures and Residuals. A specimen-delivery column connects to perimeter pens, vents, wall cavities, bait machinery, emergency shutters, and a defensive power node. Hostiles enter through physical facility openings, never generic spawn effects in player-facing presentation.

## Spatial Contract

Every Laboratory satisfies these rules:

1. The dominant apparatus is readable during the Drop.
2. At least three Landing strategies offer meaningful trade-offs.
3. No valid Landing creates an unrecoverable trap or decisive opening disadvantage.
4. The Test Floor has no single mandatory choke point.
5. Up to 24 Subjects can use broad movement paths around apparatus and edge-biased clutter.
6. Geometry, light, motion, icons, and audio carry critical state; colour is never the only cue.
7. At least one other layer of the Compound is visible through a booth, rail, vent, service route, or breach.

The Drop is individually controlled even for Partners. Adjacent tubes and visible landing options let a Pair coordinate proximity without averaging inputs or surrendering control to one Player.

## Facility State

Presentation composes four independent state layers:

- **Round stage:** controlled, questionable, or containment failure;
- **persistent state:** authored prop and route transitions retained for the Trial;
- **Experiment lifecycle:** idle, brief, entry, live, resolve, Recall; and
- **event overlay:** compatible machinery, power, containment, or environmental events.

State transitions are named, seeded, and server-authoritative. Structural walls and floors receive cosmetic state only. Selected props use authored thresholds such as `pristine`, `stressed`, `breached`, and `destroyed`; collision changes are explicit and retain a valid route. Events cannot repair state, contradict the state ledger, or make an Experiment objective impossible.

## The Collapse

The Collapse uses the complete damaged Compound. Eligible Subjects enter individually through fair, seeded sockets and receive a brief protected orientation window. Separator shutters and the perimeter route then open, followed by increasingly dangerous Core shortcuts and authored Laboratory failures.

The state ledger guarantees comparable initial hazard exposure, no initial dead ends, at least two exits from occupied areas, a dependable perimeter connection, and clear telegraphs before lethal transitions. Safe space contracts through comprehensible apparatus and route failures rather than a generic shrinking circle. Simultaneous Eliminations use survival time and a deterministic tie rule.

## Visual Language

### Facility Palette

| Role | Colour | Use |
| --- | --- | --- |
| Warm off-white | `#F1EEE6` | Primary wall panels |
| Cool light grey | `#C8CED1` | Floors and secondary structure |
| Equipment grey | `#66727A` | Rails, frames, and machinery |
| Charcoal | `#273238` | Recesses and heavy mechanisms |
| Near-black | `#172126` | Deep service spaces |
| Systems cyan | `#56D6D2` | Normal infrastructure state |
| Safety amber | `#F4C95D` | Caution and Experiment staging |
| Alarm coral | `#EE625F` | Danger, failure, and the Collapse |
| Validation green | `#69C779` | Success and safe states |
| Soft white | `#F8F4E8` | Text and luminous surfaces |

The facility stays neutral enough for Subjects, Verbs, hazards, and active apparatus to own saturated colour.

### Verb Readability

Subject identity and Verb state remain separate. Identity uses a stable suit treatment and number; Verb Effects use temporary material, silhouette, icon, and motion changes.

| Verb | Colour | Primary treatment |
| --- | --- | --- |
| BURN | `#FF6A3D` | Close flame, sparse embers, teardrop icon |
| SHIELD | `#35BCEB` | Thick shell, impact rings, bracket icon |
| GROW | `#66C95A` | Scale increase, pressure pulse, expanding-square icon |
| STRETCH | `#D45AC7` | Elongation, tapered trails, double-arrow icon |
| ROLL | `#4169D8` | Compact form, arc trails, circular-arrow icon |
| JUMP | `#F2C94C` | Compression, vertical streak, spring icon |
| BOUNCE | `#FF7DB5` | Squash, rebound ring, wave icon |
| FREEZE | `#A8E8E8` | Frosted extremities, crystals, snowflake-lock icon |
| REWIND | `#8067D8` | Positional echoes, reverse ribbons, clock icon |

Each Verb reads from silhouette or motion within roughly 150 ms, keeps effects close to the Subject, and explains the physical interaction without obscuring it.

An assumed Verb on a Residual uses the same per-Verb treatment so learned readability transfers. A Residual's Adverb reads as a separate behavioural and material overlay that modifies motion without imitating any Verb treatment, so unsanctioned grammar is never mistaken for a tenth Verb.

### Lighting

Large warm-white overhead fixtures and neutral-cool ambient light provide party-game readability. Cyan indicates normal operation, amber staging, and coral danger. Contact shadows and moderate SSAO ground actors and machinery. Glow is limited to indicators and active effects. Volumetric fog is reserved for selected breaches and Collapse events.

Player and Verb cues remain protected from aggressive grading. SDFGI, SSR, motion blur, chromatic aberration, and general film grain are outside the visual baseline.

## Environment Kit Contract

The reusable environment kit contains orthogonal floor and wall bays, radial and annular floor segments, dome-shell bays, separator corridor bays, utility-wall modules, separator-spine junctions at the Core and perimeter, 4 m doors and shutters, Assignment Deck rails, support columns, trusses, vents, panels, and material variants for clean, stressed, and breached states.

All pieces use metre scale, applied transforms, stable names, predictable origins, and snap without mesh editing. Gameplay collision remains in Godot. Radial pieces are a small specialised subset; most assets remain orthogonal and reusable across Laboratories.

The camera remains third-person. Main paths are 4–6 m wide, secondary paths 2.5–3 m wide, doors at least 4 m wide and 4.5 m high, and barriers roughly 1.1–1.3 m high. Apparatus uses large relationships—momentum, mass, timing, trajectory, pressure, balance, and cooperation—rather than tiny switches or precision placement.

## Scope Boundaries

The Compound does not use arbitrary structural destruction, runtime fracture simulation, unrestricted between-Round exploration, unique art for every state combination, generic random events that invalidate objectives, first-person interaction design, gore, or overt body horror. Support above 24 concurrent Players is outside the product boundary.
