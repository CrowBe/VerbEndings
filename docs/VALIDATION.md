# Validation Notes

## Summer Engine setup

Summer Engine is the preferred interactive validation path for this project
because it can open a Godot 4-compatible project, inspect live scene trees, run
the game, and surface console errors through its MCP/CLI workflow. The repo
keeps shared project-scoped MCP config in `.agents/mcp.json`, pointing at
`npx -y summer-engine@latest mcp`. Client-specific directories `.cursor`,
`.windsurf`, and `.claude` are symlinks to `.agents` so clients that look for
their own folder still read the same config file.

For local setup, run:

```bash
tools/setup_summer_engine.sh codex
```

Replace `codex` with your client if needed, for example `claude-code`,
`cursor`, `windsurf`, `cline`, `roo-code`, `gemini`, `github-copilot`,
`vscode-copilot`, or `opencode`. The script runs Summer's setup command and
prints the follow-up `install`, `login`, and `run .` commands when your machine
needs them.

For this review environment, Summer Engine could not be executed because the
engine is not installed/running and `npx --yes summer-engine run` failed with an
npm registry `403 Forbidden` response. The Summer Engine docs require an
installed, running engine with the project open, or running `npx summer-engine
run` from the project directory, before MCP tools can connect.

## Commands to run when Summer Engine is available

```bash
npx -y summer-engine@latest run .
```

Then, through the Summer Engine MCP tools:

1. Open `/workspace/VerbEndings`.
2. Run the project from `res://scenes/core/Game.tscn`.
3. Confirm the scene tree contains `Game/World/Players/LocalPlayer` and
   `Game/World/Round/PuzzleRound` for the default graybox boot.
4. Verify the console has no script parse errors, missing resource errors, or
   invalid node-path errors.
5. Capture a screenshot if visible gameplay changes are being reviewed.

## Static fallback used in this repository

`tools/validate_project.py` checks the main scene and every `res://` resource
reference found in `.tscn` and `.gd` files. It does not replace a Summer Engine
or Godot runtime smoke test, but it catches the most common structural mistakes
while this container lacks an engine binary.
