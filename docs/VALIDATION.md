# Validation

VerbEndings targets Godot 4.3. Imports, runtime checks, and exports use that release because newer versions may rewrite scenes or resources incompatibly.

## Static Project Check

Run from the repository root:

```bash
python3 tools/validate_project.py
```

The validator checks the configured main scene and every `res://` resource reference in `.tscn` and `.gd` files. It does not execute GDScript, physics, signals, or deferred callbacks.

## Native Import And Parse Check

```bash
godot4.3 --headless --editor --path . --quit
```

The check passes only with a zero exit status and no `ERROR`, `SCRIPT ERROR`, or parse-error output.

## Runtime Smoke Check

```bash
timeout --signal=INT --kill-after=3s 8s godot4.3 --headless --path .
```

Exit status 124 is expected when `timeout` stops a healthy running process. The complete output must contain no runtime errors or unexpected warnings.

## Local Playtest Quick Start

Running the project opens the main menu. `resources/local_playtest.tres`
configures the local roster, seed, and developer quick start. The menu offers a
player-facing local Trial plus manual host and join flows. The local flow presents timed unique
Verb claims for the configured roster, each Pair Draft, authored Experiment
Briefs, the in-Experiment HUD, Result Announcements, and the final winner.
Host and join use the entered address and port; the host starts after every
connected Subject has claimed a Verb.

The resource selects the Experiment Protocol used first by the developer quick
start, Trial seed, Subject count (one locally controlled Subject and up to eight
stationary participants), and preferred unique Verb assignments. Invalid or
duplicate preferred Verbs receive the first available Verb in canonical order.

The quick-start controls are:

- F5: start from the configured seed;
- F6: restart with the same seed; and
- F7: restart with the next seed.

During Laboratory Entry, Space Releases the locally controlled Subject from
its assigned Drop tube and WASD steers the descent. Every unreleased Subject
is automatically Released after a short presentation window so unattended
local participants cannot block the Trial.

The same seed reproduces the Protocol, global random stream used by current
Round layouts, roster identities, Verb assignments, and Pair or Self-Chain
state. Edit the `.tres` resource in the Godot inspector to change the supported
configuration without editing source code. This path uses the same domain
services as the programmatic ENet host/join flow but does not create a
multiplayer peer.

Run the player-facing Trial presentation suite with:

```bash
godot4.3 --headless --path . tests/TestTrialPresentation.tscn
```

It verifies the main menu and local/host/join entry points, timed unique Verb
claims, authoritative Pair Draft choices and odd-roster Self-Chains,
classification-free Experiment Briefs, viewport-contained lifecycle screens,
the Stability/Verb Expression/Objective/Round Score HUD, non-colour Critical
Stability cues, and individual Result Announcement rankings.

## Gameplay Tests

Run the Chain Severance suite with:

```bash
godot4.3 --headless --path . tests/TestChainSeverance.tscn
```

It verifies configurable once-only Severance Loss, the 1-Stability floor,
Self-Chain exemption, orphaned-Subject Overdrive state, and cost-free scheduled
and Collapse dissolution.

Run the focused Overdrive lifecycle suite with:

```bash
godot4.3 --headless --path . tests/TestOverdrive.tscn
```

It verifies Self-Chain entry, Collapse-wide entry, the exact 50% Verb
Expression cooldown, and cleanup when normal Pairing or Collapse resolution
ends Overdrive.

Run the Stability and Verb Expression suite with:

```bash
godot4.3 --headless --path . tests/TestStability.tscn
```

It verifies configurable Expression cost, the 1-Stability self-spend floor,
Critical Stability, external-Impact Destabilisation, Recall Restabilisation,
the always-on Stabilisation Rate and its baseline cap, and Material
absorption rules.

Run the Trial scoring and resolution suite with:

```bash
godot4.3 --headless --path . tests/TestTrialResolution.tscn
```

It verifies individual Round and Trial Scores, sole and tied First Place,
Collapse participation, protocol-authored Verb-Chain placement and bonus
sharing, Synergy-scaled shared rewards, an Eliminated Partner's shared result,
and single-payment odd-roster Self-Chains.

Run the complete non-presentation Trial lifecycle suite with:

```bash
godot4.3 --headless --path . tests/TestTrialLifecycle.tscn
```

It verifies deterministic three-Protocol sequencing, one Verb Selection,
three Pair Drafts, authored Experiment completion, Recall and result signals,
distinct Round Scores, cumulative Trial Scores, same-process replay, odd-roster
Self-Chains, sole First Place, and tied First Place handoff to the Collapse.

Run the Laboratory Entry, Drop, and Recall suite with:

```bash
godot4.3 --headless --path . tests/TestLaboratoryTransit.tscn
```

It verifies deterministic unique tube assignment, adjacent Pair tubes,
single-tube Self-Chains, the 24-Subject socket ceiling, independent Release,
steerable physics handoff, all-Subject Landing completion, floor collection
apertures, reversed-pressure Recall, and return to the Assignment Deck.

Run the two-process network session suite with:

```bash
python3 tests/run_network_session_test.py --godot godot4.3
```

It launches real headless ENet host and client processes, drives them through
Verb Selection, all three Pair Drafts and Experiments, and compares their final
replicated roster, Verbs, Pair state, scores, Protocol history, lifecycle, and
result. A second scenario disconnects the client during an Experiment and
verifies that the host safely releases it and completes the Trial.

Run the Residual grammar suite with:

```bash
godot4.3 --headless --path . tests/TestResidualGrammar.tscn
```

It verifies seeded Adverb timing and selection, one-Verb and one-Adverb caps,
the separation of Assumption from self-development, and independently visible
behaviour changes on a Verbless Residual.

Run the Experiment Protocol suite with:

```bash
godot4.3 --headless --path . tests/TestExperimentProtocols.tscn
```

It verifies deterministic seeded Protocol sequences, required authored fields,
explicit reward-sharing policies, and Experiment Brief terminology that does
not expose internal classifications.

Run the Sustained Exposure suite with:

```bash
godot4.3 --headless --path . tests/TestSustainedExposure.tscn
```

It verifies continuous atmospheric Stability Loss and eventual Destabilisation,
the absence of Impact-shed Material, survival-and-Material placement, all five
physics apparatuses as non-scoring traversal tools, elevated dispenser routes,
breakable Material housings, and an authored use for every Verb.

Run the local playtest bootstrap suite with:

```bash
godot4.3 --headless --path . tests/TestLocalPlaytestBootstrap.tscn
```

It verifies configured Protocol and seed selection, deterministic unique Verb
fallbacks, roster and actor identity, Pair and odd-roster Self-Chain state,
Overdrive, scoring reset, and same-seed/new-seed restart behaviour.

Run the animation adapter suite with:

```bash
godot4.3 --headless --path . tests/TestAnimationAdapter.tscn
```

It verifies the semantic clip names reachable through the adapter, gameplay
functioning with the visual subtree hidden, and single-Impact basic-hit
resolution for the proxy fallback, a production clip without a contact
marker, and a production clip with one.

Run the Compound topology and spatial-contract suite with:

```bash
godot4.3 --headless --path . tests/TestCompound.tscn
```

It verifies the Central Core, Assignment Deck, three 52 m Test Floors,
separator shutters, closed perimeter route, 30-degree dome modules, three
distinct and recoverable Landing strategies per Laboratory, route redundancy,
24-Subject floor-area allowance, non-colour cue hooks, cross-layer visibility
hooks, normal-Round confinement, retained Laboratory node identity, environment
kit naming and origins, metric contracts, and Godot-owned collision.

Run the Material Dispenser visual-boundary suite with:

```bash
godot4.3 --headless --path . tests/TestMaterialDispenser.tscn
```

It instantiates the production scene and verifies the imported GLB `Visual`
child exists with mesh instances and no collision descendants, the Godot-owned
cylinder collision remains outside `Visual` and enabled while `Visual` is
hidden, the overall presentation bounds (approximately 1.6 m wide, 2.0 m high,
floor offset zero, depth no more than 1.92 m, front extent approximately
1.1 m in Godot +Z), the 8,000-to-15,000 production-preparation triangle budget,
the expected surface materials, the `DispenseSocket` alignment, and dispensing
Material at the socket while `Visual` is hidden. Tight physical tolerances retain
the authored envelope while the triangle range permits deliberate topology
revision.

Run the Compound lifetime and teardown regression twice with:

```bash
python3 tests/run_compound_lifetime_test.py --godot godot4.3 --attempts 2
```

It verifies direct Compound teardown and twelve repeated Environment, PVP, and PVE
Round transitions while retaining Laboratory identity, authored state, one
active Round, and correct Player placement. The subprocess wrapper rejects
Godot errors and warnings even when the engine exits with status zero.

Run the environment-kit live-rebuild regression twice with:

```bash
python3 -m unittest tests/test_environment_kit_piece_rebuild_runner.py
python3 tests/run_environment_kit_piece_rebuild_test.py \
  --godot godot4.3 --attempts 2 --timeout-seconds 30
```

The focused Python suite verifies runner validation, timeout classification,
and process-group cleanup. The Godot regression rebuilds collidable and
collision-disabled kit pieces, waits beyond deferred node deletion, and
materially checks for a live non-empty visual mesh and the expected live
gameplay collision state. Each attempt has a positive configurable wall-clock
limit (30 seconds by default). On timeout the wrapper terminates and reaps the
Godot process group, reports captured output, and fails the attempt even if its
success marker was already printed. On Linux, the wrapper temporarily acts as
a child subreaper so orphaned descendants in the process group are also reaped
before the attempt finishes. The wrapper also rejects Godot errors and warnings
even when the engine exits with status zero.

For graphical inspection, run:

```bash
godot4.3 --path .
```

## Continuous Integration

GitHub Actions runs the static, native import and parse, and timed runtime
checks on every push and pull request. CI pins Godot 4.3.0 and exposes the
engine as `godot`, so the equivalent native commands there are:

```bash
godot --headless --editor --path . --quit
timeout --signal=INT --kill-after=3s 8s godot --headless --path .
```

Focused gameplay test suites run as separate steps after the runtime smoke
check in `.github/workflows/validation.yml`, including the Material Dispenser
visual-boundary suite. New suites belong alongside them as separate steps,
keeping failures isolated while using the same pinned engine and imported
project.

Static and headless checks do not establish visual correctness, control quality, internet traversal, latency quality, large-roster multiplayer correctness, or representative performance. Compound silhouette readability during a Drop, comfortable 8–12 Subject use, practical 24-Subject circulation, route legibility, and cross-layer sightline quality require graphical inspection and human playtesting.
