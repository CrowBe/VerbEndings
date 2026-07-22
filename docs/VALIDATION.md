# Validation Notes

Verb Endings targets Godot 4.3. Use the matching native Godot release for
imports, runtime checks, and exports; a newer engine may rewrite scenes or
resources in a format that 4.3 cannot read.

## Static validation

Run the repository validator first:

```bash
python3 tools/validate_project.py
```

It checks the configured main scene and every `res://` resource reference in
`.tscn` and `.gd` files. This catches common structural mistakes but does not
execute GDScript, physics, signals, or deferred callbacks.

## Native Godot import and parse check

From the repository root, run:

```bash
godot4.3 --headless --editor --path . --quit
```

The command imports resources and catches script parse errors, missing
resources, and invalid scene data. Treat any `ERROR`, `SCRIPT ERROR`, parse
error, or non-zero exit as a failed check.

## Runtime smoke test

Run the main scene long enough to exercise startup, physics, and deferred work:

```bash
timeout --signal=INT --kill-after=3s 8s godot4.3 --headless --path .
```

Exit code 124 is expected when `timeout` stops an otherwise running game. Read
the complete output for errors and warnings; process lifetime alone is not a
passing result.

For graphical review, run `godot4.3 --path .` in a desktop session. A clean
headless smoke test does not prove visuals, controls, gameplay flows,
multiplayer behaviour, or representative rendering performance.
