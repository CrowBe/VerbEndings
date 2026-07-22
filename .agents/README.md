# Shared agent configuration

This directory is the canonical home for project-scoped agent configuration.
Client-specific directories such as `.cursor`, `.windsurf`, and `.claude` are
symlinks to this directory so every tool reads the same `mcp.json` definition.
