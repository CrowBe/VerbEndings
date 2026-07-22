#!/usr/bin/env bash
set -euo pipefail

AGENT="${1:-codex}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cat <<MSG
Setting up Summer Engine for Verb Endings.

Project: ${PROJECT_ROOT}
Agent:   ${AGENT}

This script uses npx so it does not require a global summer-engine install.
It may download the Summer CLI and, if missing, the Summer Engine app.
MSG

npx -y summer-engine@latest doctor --json || true
npx -y summer-engine@latest setup "${AGENT}" --yes --scope user

cat <<MSG

Next local steps:
1. If doctor reports that the engine app is missing, run:
   npx -y summer-engine@latest install
2. If doctor reports that login is required, run:
   npx -y summer-engine@latest login
3. Start this project in Summer Engine:
   cd "${PROJECT_ROOT}"
   npx -y summer-engine@latest run .
4. Restart your agent/client so it reloads the Summer MCP config.
5. Ask the agent: "Use Summer Engine to run the main scene and report console errors."
MSG
