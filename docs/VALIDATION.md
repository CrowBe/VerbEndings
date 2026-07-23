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
Critical Stability, external-Impact Destabilisation and Restabilisation.

For graphical inspection, run:

```bash
godot4.3 --path .
```

Static and headless checks do not establish visual correctness, control quality, complete Trial behaviour, multiplayer correctness, or representative performance. Those claims require focused runtime scenarios and human playtesting.
