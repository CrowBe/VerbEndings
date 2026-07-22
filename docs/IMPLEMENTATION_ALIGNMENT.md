# Implementation Alignment

[`CONTEXT.md`](../CONTEXT.md) is the canonical domain and gameplay reference. This audit records the major prototype drift found on 22 July 2026 and splits migration into independently reviewable work.

## Delivery Principles

- Preserve a runnable prototype after every pull request.
- Prefer domain-correct behaviour over mechanical renames.
- Keep compatibility aliases only where they make a staged migration safer.
- Do not combine the Compound art build with core scoring and state-model refactors.
- Treat exact balance values as tunable; protect the relationships in `CONTEXT.md` with tests.

## Drift Audit

| Area | Current Prototype | Canonical Direction |
| --- | --- | --- |
| Trial resolution | `SuddenDeathManager` sums current Partner scores into team totals | Rank individual Trial Scores; only tied First Place enters the Collapse |
| Solo operation | Multiple Overdrive effect and speed multipliers | Overdrive halves Verb Expression cooldown only |
| Subject resource | `health`, `damage`, `died`, `revive` | Stability, Impact, Destabilisation, Elimination and Restabilisation |
| Verb use | Activation signals and cooldown-only use | Verb Expression with Base Expression Cost, floored at 1 Stability |
| Pair lifecycle | Pairing is primarily Trial-start state | Verb Selection once per Trial; Pair Draft and Verb Chain once per Round |
| PVE identity | `SwarmMonster`, monster groups and monster-facing APIs | Residual entity; Creature before reveal; Swarm only for group behaviour |
| Facility flow | Spawn, arena and zone abstractions | Assignment Deck, Laboratory Entry, Dispensing Line, Drop, Experiment and Recall |
| Documentation | Historical arena, match, activation and `graybox` language | Canonical vocabulary in `CONTEXT.md`; historical docs labelled or migrated |
| Multiplayer validation | Primarily local prototype tests | Deterministic odd-roster, three-Round and Collapse scenarios with real peers |

## Tracked Work

- [#5 — Align Trial scoring, Round pairing, and Collapse resolution](https://github.com/CrowBe/VerbEndings/issues/5)
- [#6 — Replace health and Verb Activation with Stability and Verb Expression](https://github.com/CrowBe/VerbEndings/issues/6)
- [#7 — Reduce Overdrive to the canonical cooldown rule](https://github.com/CrowBe/VerbEndings/issues/7)
- [#8 — Rename PVE monsters as Residuals without spoiling the reveal](https://github.com/CrowBe/VerbEndings/issues/8)
- [#9 — Implement Laboratory Entry, Drop, and Recall in the Compound greybox](https://github.com/CrowBe/VerbEndings/issues/9)
- [#10 — Add deterministic multiplayer scenarios for the canonical Trial lifecycle](https://github.com/CrowBe/VerbEndings/issues/10)

## Recommended Sequence

1. Correct Trial scoring, Pair lifecycle and Collapse entry conditions.
2. Introduce Stability and Verb Expression behind compatibility boundaries.
3. Reduce Overdrive to its single cooldown rule.
4. Rename and remodel Residual-facing PVE code.
5. Implement the Dispensing Line, Drop and Recall transitions in the Compound greybox.
6. Add deterministic multiplayer scenarios and remove compatibility aliases once covered.
