# Wiki catalog (machine index)

`wiki_catalog.json` is the structured index the wiki build reads. It lists the same asset families as [`REFERENCE_ASSET_MAP.md`](REFERENCE_ASSET_MAP.md) and adds wiki-only paths (sheet, thumb, optional GLB, detail page id).

## Roles

| File | Role |
| --- | --- |
| `REFERENCE_ASSET_MAP.md` | Human-facing canon for evidence classes and missing evidence prose |
| `wiki_catalog.json` | Machine rows for catalog cards, detail stubs, and media |
| `docs/wiki/story_sources.json` | Which headings from `GLOSSARY.md` / `WORLD_DESIGN.md` become story HTML |
| `tools/wiki/generate.py` | Writes HTML under `wiki/` from those sources |

Do not invent a second evidence classification in the JSON. Keep `evidence` values aligned with the map. When a family is added to the map, add a matching row here (or the generator will omit it from the wiki).

## Schema (`verbendings.wiki_catalog/v1`)

- `sections[]`: `{ id, title, assets[] }`
- `assets[]`: `{ id, title, evidence, sheet?, thumb?, glb?, detail_page?, blurb, map_row }`
  - Paths are repo-relative (`docs/art/...`, `assets/...`).
  - `detail_page` is a wiki slug (`shared-subject`, `material-dispenser`) when a dedicated page exists; omit when the catalog card is enough.
- `media[]`: videos/images surfaced on `wiki/media/` (FLUX intro today).
- `sheets_root`: directory scanned for the sheets gallery.

## Story sources (`verbendings.wiki_story/v1`)

Each page lists `blocks` as `{ source, heading, as }`. The generator copies the Markdown section body under that heading into the wiki. Edit the canon docs, not the HTML.

## Generate

```bash
python3 tools/wiki/generate.py
cd wiki && npm run build
```

Generated HTML carries `<!-- generated: tools/wiki/generate.py — edit sources, not this file -->`.
