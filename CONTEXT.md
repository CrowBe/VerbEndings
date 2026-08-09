# VerbEndings Context

This document is the canonical source of truth for VerbEndings domain language and gameplay relationships. Code, UI, narrative text, tests and design documents use it. Balance values remain configurable unless a relationship is explicitly stated here.

## Domain Model

### Participants And Subjects

- A **Player** is the human or network participant.
- A **Subject** is the living playable entity controlled by a Player during a Trial.
- **Semantic Adaptation Droplet (SAD)** is the facility's formal classification for the adaptive substrate from which a Subject originates.
- **Blob** is the Researcher's sole affectionate colloquialism for a Subject.
- A Subject claims one unique **Verb** during Verb Selection and keeps it for the whole Trial.

Do not use `character`, `unit`, `avatar`, `Droplet`, `Drop` or `blob` interchangeably with Subject. Droplet describes classification and origin; Drop has a separate lifecycle meaning below.

### Programme And Trial Lifecycle

- The **Ultimate Lexical Trial Programme** is the ongoing institutional programme.
- A **Trial** is one complete game session.
- A Trial contains exactly three **Rounds**.
- Each Round contains one scored **Experiment**.
- **Match** is not a domain term.

Verb Selection occurs once at the start of a Trial. Each Round then follows this lifecycle:

1. **Pair Draft**
2. **Experiment Brief**
3. **Laboratory Entry**
4. **Experiment**
5. **Recall**
6. **Result Announcement**
7. Optional **Thematic Moment**

The next Round creates new Pairs. A Subject retains its Verb but not its Partner.

### Pairing And Verb Chains

- **Pairing** is the draft action in which one Subject chooses another.
- A **Pair** is the temporary grouping of two Subjects for one Round.
- Each Subject in a Pair is the other's **Partner**.
- A **Verb Chain** is the gameplay bond formed from the Pair's two Verbs.
- A **Synergy Coefficient** expresses compatibility between those Verbs and may modify shared effects and scoring.
- A **Self-Chain** is the single-Subject Verb Chain used when an odd roster leaves one Subject without a Partner.
- **Overdrive** is the solo operating state available to a Self-Chain and to every surviving Subject during the Collapse.
- **Chain Severance** is a Verb Chain ending early because a Partner is Eliminated during an Experiment.

A Subject draws part of its own cohesion from its Partner's Verb, so Chain Severance costs the surviving Subject Stability. A Self-Chain has no Partner to lose and can never be Severed.

Chain Severance never grants Overdrive. Overdrive comes only from entering a Round Self-Chained or from the Collapse, so a Subject orphaned mid-Experiment finishes that Experiment alone and unaided. A Partner's mistakes and a Partner's successes both reach the Subject beside them, and that exposure is the point of Pairing rather than a rough edge to file off.

Scheduled dissolution is not Severance: a Pair and its Verb Chain end after every Experiment at no cost, and the Collapse dissolving all Pairs at once is a lifecycle transition rather than a loss. Points belong to Subjects, never to a Pair. `Team`, `partnership` and `Pair Score` are not canonical domain nouns.

## Verb Expression And Stability

### Verb Expression

- **Verb Expression** is a Subject intentionally manifesting its Verb.
- **Express** is the canonical action: "The Subject Expresses GROW."
- A **Verb Effect** is the resulting physical state or behaviour.
- An **Expression Cost** is the Stability consumed by an Expression.
- Each Verb has a configurable **Base Expression Cost**.

`Verb Activation`, `ability use` and `cast` are not domain terms.

### Stability

- **Stability** is a Subject's current capacity to maintain its form and is the visible gameplay resource.
- **Stability Loss** is a reduction caused by an Impact, hazard or Protocol-specific effect.
- **Severance Loss** is the Stability Loss a Subject suffers when Chain Severance takes its Partner's Verb away from it.
- **Restabilisation** restores Stability where an effect permits it.
- **Stabilisation Rate** is the small, always-on Restabilisation every Subject receives, expressed as a percentage of baseline Stability. It cannot raise Stability above baseline.
- **Critical Stability** is single-digit Stability. It receives strong visual and audio deformation cues, but no additional movement or power penalty by default.
- An **Impact** is an external force or hazard capable of reducing Stability to zero.
- **Destabilisation** is the physical failure state reached at zero Stability.
- **Elimination** is removal from the active Experiment or Collapse.

Every Subject uses the same baseline Stability. A Verb uses the same Base Expression Cost whether the Subject is Paired or Self-Chained. Paying an Expression Cost cannot reduce Stability below `1`; only an Impact can Destabilise a Subject.

Severance Loss follows the same floor. It is a configurable balance value, it applies once per Severance, and it cannot reduce Stability below `1`, so losing a Partner never Destabilises the Subject that survives.

During a normal Experiment, a Destabilised Subject is Eliminated from that Experiment and automatically Recalled. It returns in the next Round. During the Collapse, Recall is unavailable and Elimination is permanent for the remainder of the Trial.

`Health`, `hit points`, `damage`, `alive`, `death` and `killed` are not canonical UI or narrative terms. **Disposal** is reserved for the hidden fate of failed earlier Droplets.

### Material

- **Material** is the substrate resource a Subject **absorbs** to Restabilise. It is the only such resource.
- Material has two sources: it is **shed on Impact** by a Residual or Subject, and it is **dispensed** by the Semantic Engine as an environmental supply.
- Absorbing Material Restabilises the Subject and cannot raise Stability above baseline. The Material shed by an Impact and the amount each unit restores are configurable balance values.
- During the Collapse the Semantic Engine is offline and dispenses no Material. Material shed on Impact still appears, constrained by the pace of Residual activity during the Collapse.

Capitalised **Material** always means this substrate resource. Lower-case "material" is reserved for surface and rendering description and never refers to the resource.

### Overdrive Rules

Overdrive changes one relationship only: Verb Expression cooldown is halved.

- Baseline Stability is unchanged.
- Base Expression Cost is unchanged.
- Verb Effect strength is unchanged.
- The same rule applies to a Self-Chain during a normal Round and universally during the Collapse.
- Chain Severance grants nothing: an orphaned Subject keeps its normal cooldown.

Any further multiplier requires playtest evidence rather than being part of the domain rule.

## Scoring And Trial Resolution

- **Round Score** is the score owned by one Subject for one Round, including rewards shared through its Verb Chain.
- **Trial Score** is that Subject's cumulative score across all three Rounds.
- **Trial Ranking** orders Subjects by Trial Score after a Result Announcement.
- **First Place** is the highest individual Trial Score after Round Three.
- The **Trial Winner** is the sole Subject in First Place, or the last surviving Subject after the Collapse.

If exactly one Subject holds First Place after Round Three, that Subject wins. If two or more Subjects tie for First Place, the Trial triggers **the Collapse**. The Semantic Engine issues **SURVIVE**, all Pairs dissolve, all survivors enter Overdrive and the last remaining Subject wins.

`Pair Score`, `team score`, `ladder` and `Sudden Death` are not domain terms. **Finale** may be descriptive prose, but is not a lifecycle state.

## Experiments And The Compound

### Experiment Definition

- An **Experiment Protocol** is the authored ruleset defining objectives, hazards, scoring and completion conditions for an Experiment.
- An **Experiment Brief** is the player-facing explanation of the selected Protocol before Laboratory Entry.
- An **Objective** is a concrete task established by the Protocol.
- Environment, PVP and PVE are development and marketing classifications, not in-world names.

### Facility Language

- The **Compound** is the complete faceted hemispherical facility.
- The **Assignment Deck** is the elevated annular hub used for Verb Selection, Pair Drafts and Result Announcements.
- The **Central Core** contains the Semantic Engine's physical infrastructure and primary machinery.
- A **Laboratory** is one of the three named experimental environments.
- The **Test Floor** is the continuous playable area within a Laboratory.
- A **Separator Spine** is a non-zero-width radial structure between neighbouring Laboratories. It belongs to the Compound rather than either Test Floor and contains observation, utility, shutter, and connective infrastructure.
- A **Service Route** is a normally sealed corridor through a Separator Spine or around the Compound perimeter. Service Routes become playable only during an authored transition such as the Collapse.
- **Sector** is limited to literal radial geometry or streaming boundaries.
- **Zone** is limited to generic spatial triggers in technical discussion.

The three Laboratories are:

- **Applied Attrition Laboratory** — tests how long a Subject holds its form in an unstable environment.
- **Competitive Stress Laboratory** — measures dominance, displacement and resilience.
- **Adaptive Containment Laboratory** — tests survival against contained creatures and failed predecessors.

`Arena` and `chamber` do not mean Laboratory or Test Floor. Use Australian/British **greybox** in prose.

### Laboratory Entry And Recall

- **Laboratory Entry** is the Round phase before the Experiment.
- The **Dispensing Line** is the overhead conveyor and tube system carrying Subjects from the Assignment Deck.
- The **Drop** is the playable entry sequence comprising Release, steerable descent and Landing.
- **Release** is the Player-controlled moment a Subject exits its tube.
- **Landing** is the resulting arrival on the Test Floor.
- **Recall** is the post-Experiment return to the Assignment Deck.

Partners travel in adjacent tubes, independently coordinate their Releases and steer their Drops to land within useful Verb Chain range. At Experiment conclusion, the Dispensing Line reverses pressure and floor collection apertures pull Subjects into the shared tube network before presentation returns to the Assignment Deck.

`Insertion Vector`, `Landing Point`, `deployment`, `extraction`, `recovery` and `return` are not canonical lifecycle terms. `Spawn` remains technical implementation language only.

### Residuals

- A **Residual** is a previous-generation Droplet that survived disposal and now inhabits the Compound.
- All initial PVE hostiles are Residuals.
- **Creature** is the generic term used in Experiment Briefs before their identity is revealed.
- **Swarm** describes group behaviour or encounter shape, not a species.
- **Enemy** and **hostile** describe gameplay relationships only.

The Residual reveal occurs through the environment first, then is accidentally confirmed by the Researcher during a Thematic Moment.

### Residual Grammar

- **Assumption** is a Residual taking the Verb of a Subject it Destabilises. An assumed Verb is always taken, never self-developed.
- An **Adverb** is the unsanctioned modifier a Residual develops itself after surviving long enough. The survival threshold is a configurable balance value.
- A Residual's Adverb modifies every action it performs, including ordinary movement, attacks and an assumed Verb.
- A Residual holds at most one assumed Verb and at most one Adverb.
- Assumption and Adverb development strengthen a Residual. The magnitude of any strengthening is a configurable balance value, not a domain rule.
- The Semantic Engine issues only Verbs. No Subject holds an Adverb, and no facility system sanctions one.

## Institutional Voices

- The **Semantic Engine** is the authoritative facility system. It selects Experiment Protocols, issues Experiment Briefs, records scores, presents Result Announcements and issues `SURVIVE`.
- The **Researcher** is one specific older Scientific Researcher assigned to the cohort and subordinate to the Semantic Engine.
- The Researcher sincerely follows instructions, explains procedures and provides the Trial's human voice.
- Their likeability, naivety and physical clumsiness support brief slapstick moments.
- Their careless remarks and incomplete understanding create accidental lore disclosures and fridge horror.
- The Researcher is neither the rules authority nor secretly omniscient.
- A **Result Announcement** is the Semantic Engine's formal presentation of Round Score and Trial Ranking.
- A **Thematic Moment** is an optional post-announcement narrative beat delivered through dialogue, an environmental event or a short staged sequence.

`Announcer` and `host` are not character roles. `Cinematic` describes a possible production format for a Thematic Moment, not a domain event.

## Canonical Usage Examples

> During Pair Draft, each Subject selects a Partner and forms a Verb Chain for the Round.

> The Semantic Engine presents the Experiment Brief before the Dispensing Line carries each Pair into the Applied Attrition Laboratory.

> An Expression can leave a Subject at Critical Stability, but only an Impact can Destabilise it.

> Round Three ended with three Subjects tied for First Place, so the Semantic Engine initiated the Collapse and issued SURVIVE.

> The Researcher called the Subjects "blobs" before accidentally revealing that the creatures were Residuals.

> The oldest Residual developed the Adverb VIOLENTLY, then assumed BURN from the Subject it Destabilised.
