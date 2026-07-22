# Verb Endings Arena and Visual Design

## Purpose

This document defines the visual language, world fiction, arena structure and
state model for the first complete version of *Verb Endings*. It turns the
existing multiplayer greybox into a coherent production target without
changing its central loop:

`verb selection -> pair draft -> synced insertion -> experiment -> results/extraction`

The game should feel like a meeting point between the friendly physical comedy
of *Fall Guys* and the grounded industrial clarity of *Portal*. Physics remains
the primary source of play and humour.

## Creative Foundation

The five art-direction adjectives are **clinical, buoyant, tactile,
overconfident and quietly uncanny**.

The facility is conducting the Ultimate Lexical Trial, a programme intended to
identify the most powerful word. Players are compact, rounded humanoids grown
by the facility to accept lexical properties. The institution calls them
Semantic Adaptation Units; the researcher may use a warmer nickname in
dialogue.

The subjects' origin is introduced cheerfully and incompletely, then revealed
through signage, researcher slips and environmental evidence. They develop
personality and agency despite being treated as interchangeable units. In the
finale, SURVIVE is powerful because the subjects enact it rather than because
the facility assigned it.

### Semantic Engine

The facility is controlled by a faceless Semantic Engine. It communicates
through printed plans, status panels, indicator lights and automated machinery,
not through a personified voice or avatar. It treats language as a measurable
set of tokens and optimises for force, survival and dominance without
understanding context or relationships.

This provides AI-era subtext without making the story a topical lecture. The
themes are proxy metrics, literal interpretation, institutional faith in an
inscrutable system and the limits of ranking meaning.

### Lead Researcher

The sole speaking character is a competent, lovable lead researcher who trusts
the Semantic Engine too readily. He turns alarming directives into cheerful
briefings, uses regular wordplay and remains convinced that every accident
produces valuable data.

His poor eyesight creates physical comedy rather than intellectual incapacity:
tiny printouts, smudged lenses, glasses falling into apparatus and confident
readings of the wrong page. His arc culminates in ignoring protocol and helping
the subjects survive. Without his glasses, he finally stops reading the system
and looks directly at them.

### Fridge Horror

The horror ceiling is unsettling implication, cute-creepy creatures and no
gore. Previous-generation subjects survive in service corridors, cupboards,
vents and wall cavities. They can absorb verb traits imperfectly because they
share the players' adaptive substrate.

They should be funny at first glance and sad on reflection. Horror comes from
classification labels, discarded ID bands, obsolete experiments, nesting
behaviour and what the institution considers normal. Enemies enter through
physical parts of the facility rather than generic spawn effects.

## Visual Foundation

The game uses stylised PBR: rounded, simplified geometry with believable
materials, lighting, mass and contact. It avoids heavy photo-textures and a full
toon shader.

Godot implementation uses:

- `MeshInstance3D` scenes and Blender-authored `.glb` files for the modular kit;
- `StandardMaterial3D` resources for painted metal, rubber, glass, emissive
  screens and subject bodies;
- custom shaders only for specialised effects such as verb overlays, heat
  distortion, shield refraction and damage transitions;
- `GPUParticles3D`, animated meshes and local lights for flame, smoke, sparks
  and debris;
- reusable `.tscn` modules for structural bays, apparatus and stateful props.

### Facility Palette

| Role | Colour | Use |
| --- | --- | --- |
| Warm off-white | `#F1EEE6` | Primary wall panels |
| Cool light grey | `#C8CED1` | Floors and secondary structure |
| Equipment grey | `#66727A` | Rails, frames and machinery |
| Charcoal | `#273238` | Recesses and heavy mechanisms |
| Near-black | `#172126` | Deep service spaces; never pure black |
| Systems cyan | `#56D6D2` | Normal AI and status infrastructure |
| Safety amber | `#F4C95D` | Caution and experiment staging |
| Alarm coral | `#EE625F` | Danger, failure and collapse |
| Validation green | `#69C779` | Success and safe states |
| Soft white | `#F8F4E8` | Text and luminous surfaces |

The facility remains neutral enough that players, verbs, hazards and active
apparatus own the saturated colours. Colour is never the only cue.

## Verb Visual Language

Player identity and verb state remain separate. Suit colour and number identify
the player. Verbs appear as temporary material overlays, silhouette changes,
icons and motion signatures.

| Verb | Colour | Visual treatment |
| --- | --- | --- |
| BURN | `#FF6A3D` | Close clean flame, sparse embers, restrained heat distortion and a teardrop-flame icon |
| SHIELD | `#35BCEB` | Thick translucent shell, concentric impact rings, planted stance and containment-bracket icon |
| GROW | `#66C95A` | Real scale increase, reinforced seams, pressure pulse and expanding-square icon |
| STRETCH | `#D45AC7` | Elongated body, elastic joint bands, tapered trails and horizontal double-arrow icon |
| ROLL | `#4169D8` | Compact rounded form, rotational suit track, arc trails and circular-arrow icon |
| JUMP | `#F2C94C` | Compressed anticipation, bright leg chevrons, vertical streak and spring/up-arrow icon |
| BOUNCE | `#FF7DB5` | Elastic highlight, impact squash, rebound ring and repeating-wave icon |
| FREEZE | `#A8E8E8` | Desaturated overlay, frost at extremities, sparse crystals and snowflake/lock icon |
| REWIND | `#8067D8` | Positional echoes, reverse-flow ribbons, scanline snap and anticlockwise-clock icon |

Every effect must:

1. read within roughly 150 ms from silhouette or motion before colour;
2. stay close to the body so multiplayer scenes remain legible; and
3. explain the physics interaction rather than obscure it.

## Lighting and Facility Progression

Lighting is bright enough for party-game readability while preserving physical
weight and service-space depth.

- Use filmic tonemapping with low-energy neutral-cool ambient light.
- Large soft overhead fixtures provide warm-white key light.
- Cyan strips communicate normal system state.
- Contact shadows and moderate SSAO ground actors and machinery.
- Glow is restrained to indicators, active verbs and effects.
- SDFGI, SSR, motion blur, chromatic aberration and general film grain remain
  off initially.
- Start with MSAA 2x, but preserve legibility without it.
- Reserve volumetric fog for selected breach and Collapse moments.

Visual degradation follows match stage rather than round type:

1. **Controlled experiment:** clean panels, soft overhead light, cyan status
   strips and little debris.
2. **Questionable progress:** amber staging, temporary cables, replacements and
   hurried repairs.
3. **Containment failure:** exposed service spaces, interrupted coral alarms,
   rattling vents, sparks and failed prototypes at the margins.
4. **SURVIVE:** incoherent system lighting, cold emergency light, warm fire,
   moving shadows and collapsing architecture.

Player and verb cues remain protected from aggressive scene grading in every
state.

## Camera and Interaction Scale

The current third-person camera remains the baseline. First-person is outside
the initial scope and should only be reconsidered if playtesting finds a
valuable interaction that cannot be redesigned for third-person.

Puzzles use large physical relationships: momentum, mass, timing, trajectory,
pressure, balance and cooperation. Avoid tiny switches, precise aiming and
fine object placement. Interactions use generous volumes, clear silhouettes and
large readable apparatus.

## Modular Arena Kit

The facility uses a 2 m planning grid with 1 m detail increments.

- Subject reference height: approximately 1.6 m before GROW.
- Main paths: 4-6 m wide.
- Soft-barrier routes: 2.5-3 m wide.
- Standard chamber: approximately 24 x 24 m, expandable in 8 m bays.
- Major apparatus chamber: 32-48 m across with 10-16 m clear height.
- Standard doors: 4 m wide and 4.5 m high.
- Guardrails and low barriers: 1.1-1.3 m high.

Service voids behind damaged surfaces have real depth rather than terminating
in black planes.

Kit families are:

- structural shell: floors, wall bays, corners, trusses, windows and recesses;
- navigation: doors, shutters, ramps, stairs, lifts, rails and soft barriers;
- apparatus: pistons, fans, conveyors, plates, launchers, rotating arms,
  balance platforms and containment frames;
- dressing: cabinets, trolleys, printers, monitors, cable trays, vents, bins
  and safety signage;
- stateful hero props: cupboards, glass units, machinery housings and gates;
- backstage ecology: creature entrances, nesting cavities, discarded subject
  equipment and obsolete labels.

Every chamber has one dominant apparatus silhouette readable from entry. Main
routes read through geometry and light before UI markers. Clutter stays at the
edges of puzzle-critical space. Each zone exposes at least one other facility
layer through an observation booth, service corridor, ceiling rail or damaged
recess.

## Persistent Compound

The compound is radial and layered:

- an elevated Assignment Deck and researcher booth overlook the facility;
- ceiling insertion rails branch towards three official experiment zones;
- Puzzle, PVP and PVE chambers surround a central structural core;
- public transition corridors create a readable ring;
- hidden service passages connect zones underneath the official map;
- extraction machinery returns subjects to the Assignment Deck.

Official zones are visible and understandable. Service routes, creature spaces
and the facility's unsettling history remain hidden until damage exposes them.
Hard structure takes cosmetic damage only. Authored gates control official
progression. Breakable vents, grates, cupboards, glass and maintenance panels
reveal optional routes, enemies, props and lore.

Normal experiments physically contain players within the active scoring space.
Previously used zones remain visible and preserve their damage. The Collapse
opens the full compound, including service routes revealed during the run.

## Match Flow and Insertion

The Assignment Deck hosts verb selection and pair drafting. A numbered Synced
Insertion Vector launches only when both partners board it. It accelerates along
ceiling rails and drops or fires the pair towards the active chamber.

During descent, the pair completes a short landing challenge. Both players'
inputs are averaged into one trajectory. They choose between safer placement
and riskier positional advantage while previewing the apparatus and hazards.
Landing affects the opening but cannot decide the round or create an
unrecoverable disadvantage.

After selection and pairing are locked, the Semantic Engine prints the next
experiment plan. The researcher announces the mode and the rails rotate towards
the chosen zone. Players cannot revise their verbs or pair after the reveal.

PVP, PVE and Puzzle are randomised without replacement. This blind selection
rewards flexible pairs, while the shrinking set of remaining modes creates
informed strategy in later drafts. Every verb must remain viable in every mode.

After each experiment, subjects are extracted to the Assignment Deck for
results and the next draft. This maintains pace and avoids unfocused
between-round wandering.

## Arena State Model

Each zone composes four independent layers rather than using a separate scene
for every combination:

1. **Stage baseline:** controlled, questionable or containment-failure based on
   match stage.
2. **Persistent run damage:** named prop transitions caused by players and
   researcher mishaps.
3. **Experiment lifecycle:** idle, briefing, insertion, live, resolving and
   extraction.
4. **Mid-round overlay:** compatible events such as low gravity, power loss,
   monster breach, conveyor reversal, heat surge or structural warning.

State changes are authored and discrete. Structural navigation changes only
through named, tested transitions with fallback routes. Mid-round events may
advance damage but cannot repair props or contradict the state ledger.

Each event declares compatible zones, stage ranges and required intact props.
Critical apparatus degrades into altered behaviour rather than becoming
unusable. Visual composition favours material parameters, decals, particles,
lights and mesh swaps; collision changes are rare and explicit.

Initial production scope per zone is:

- three stage presentations;
- four to six persistent hero props; and
- three to four compatible event overlays.

The authoritative server owns the run seed and state ledger. The seed covers
round order, baseline variants, researcher mishaps, eligible breaches and
Collapse events. Clients reproduce presentation from authoritative transitions.

## Stateful Damage

Structural walls and floors only receive cosmetic material or decal changes.
Selected props use authored thresholds such as `pristine -> stressed ->
breached -> destroyed`, with verb-specific effects and explicit collision
changes where required.

Between rounds, short pre-authored researcher mishaps can advance scoped damage:
dropped equipment, an early test-arm activation or a trolley reversing into a
cabinet. These sequences are selected by the run seed and leave persistent,
network-safe consequences.

## SURVIVE — The Collapse

The familiar insertion ritual fails. Pair chains dissolve and the system routes
individual subjects to authored insertion sockets across the entire compound.
Spawn selection enforces separation, comparable initial hazard exposure and a
brief protected control window.

All experiment gates fail or retract. Previous damage affects movement, monster
routes and safe-space options. Seeded waves of machinery failure, fire,
partitions, monster breaches and unstable surfaces progressively remove safe
space. The last living subject wins. Simultaneous eliminations resolve through
survival time and a deterministic tie rule.

The finale turns accumulated spatial knowledge into the last test: normal rounds
teach the compound chamber by chamber; The Collapse asks players to understand
the whole damaged system under pressure.

## Production Boundaries

The first implementation does not include:

- arbitrary structural destruction or fracture simulation;
- first-person interaction design;
- unrestricted between-round exploration;
- unique art assets for every state combination;
- a personified facility AI;
- gore or overt body horror; or
- random events that can invalidate a round objective.

Blender work begins only after this design and its implementation plan are
approved. Assets should be produced against the dimensions, palette, material
contract and state interfaces in this document.
