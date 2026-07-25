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

## Gameplay Tests

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
Critical Stability, external-Impact Destabilisation, Restabilisation, and
Material absorption rules.

Run the Trial scoring and resolution suite with:

```bash
godot4.3 --headless --path . tests/TestTrialResolution.tscn
```

It verifies individual Round and Trial Scores, sole and tied First Place,
Collapse participation, and odd-roster Self-Chains.

Run the Residual grammar suite with:

```bash
godot4.3 --headless --path . tests/TestResidualGrammar.tscn
```

It verifies seeded Adverb timing and selection, one-Verb and one-Adverb caps,
the separation of Assumption from self-development, and independently visible
behaviour changes on a Verbless Residual.

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
check in `.github/workflows/validation.yml`. New suites belong alongside them
as separate steps, keeping failures isolated while using the same pinned
engine and imported project.

Static and headless checks do not establish visual correctness, control quality, complete Trial behaviour, multiplayer correctness, or representative performance. Those claims require focused runtime scenarios and human playtesting.
