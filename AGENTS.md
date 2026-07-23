# Project Instructions

## Documentation

- Document the repository and product as they exist now. Write present-state reference material, not narratives about how the implementation or design changed.
- Do not add changelogs, ADRs, migration diaries, dated audit documents, "before and after" comparisons, superseded terminology notes, or sections describing past implementations.
- Keep planned work in GitHub issues. Documentation may state current limitations and invariants, but must not duplicate an issue backlog or delivery sequence.
- Update affected documentation in the same change as code or design decisions so every document remains internally consistent.
- Use `CONTEXT.md` for canonical product rules and domain language, `docs/ARCHITECTURE.md` for implemented software structure, and focused reference documents for other durable concerns.
- Use Australian/British spelling in prose.

## Validation

- Run `python3 tools/validate_project.py` after changing project resources or documentation links.
- Use Godot 4.3 for import, parse, runtime, and export checks.
