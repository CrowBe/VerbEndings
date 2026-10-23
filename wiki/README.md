# VerbEndings wiki (spike)

In-repo static wiki for story, art, and 3D concept models. Styled like a game wiki (sidebar + article pages), not a marketing site.

## Run (spike)

```bash
cd wiki
npm install
npm run dev
```

Open the printed local URL. GLBs, reference sheets, and the FLUX intro are symlinked from the repo (`public/models`, `public/art/*`) — no duplicated binaries. CI pulls Git LFS.


## Theme (repo tokens only)

| Token source | Use in wiki |
| --- | --- |
| `docs/WORLD_DESIGN.md` Facility Palette | CSS variables `--ve-*` (off-white, equipment grey, charcoal, near-black, systems cyan, amber, coral, validation green, soft white) |
| `scripts/presentation/TrialPresentation.gd` | Dark HUD/lifecycle panels, cyan rim borders, banner text tint |
| `scripts/environment/Compound.gd` | Confirms the same hex values in runtime environment consts |
| Typeface | None specified in-repo → system UI stack (Godot Control default behaviour) |

Do not invent a marketing brand or a second palette. Verb colours stay for Verb pages later; the shell uses facility/infrastructure colours only.

## Viewer

Asset pages use [`@google/model-viewer`](https://modelviewer.dev/) from the Google CDN. Three.js is not used in this spike.

## Proposed full layout (not all built)

```text
wiki/
  package.json                 # Vite app
  vite.config.js
  styles/wiki.css
  index.html                   # home
  story/
    index.html                 # world / trial (from GLOSSARY + WORLD_DESIGN)
    laboratories.html          # Applied Attrition / Competitive Stress / Adaptive Containment
    compound.html              # topology, Assignment Deck, Collapse
  assets/
    index.html                 # catalog grid
    shared-subject.html        # model-viewer + brief excerpts
    material-dispenser.html
    <family>/<asset>.html      # one page per REFERENCE_ASSET_MAP row as packages land
  content/                     # optional later: MD sources compiled into pages
  public/
    models/                    # symlinks → ../assets/source|exports/**/*.glb
    art/                       # symlinks → ../docs/art/** crops & renders
  README.md
```

Repo canon stays where it is (`GLOSSARY.md`, `docs/WORLD_DESIGN.md`, `docs/art/**`). The wiki **cites and displays**; it does not become a second source of truth.

### Later (out of spike)

- Generate catalog pages from `REFERENCE_ASSET_MAP.md` + `docs/art/**/BRIEF.md`
- Search (Pagefind or VitePress search)
- Godot `.gdignore` keeps `wiki/` out of the editor; keep `wiki/dist` gitignored

## Coverage

| Page | Status |
| --- | --- |
| Home + sidebar shell | done |
| Story & world (cited excerpts) | done |
| FLUX intro media page (MP4 + frames) | done |
| Asset catalog (48 map families + evidence badges) | done |
| Reference sheets gallery (47 generated sheets) | done |
| Shared Subject + model-viewer + turnaround refs | done |
| Material Dispenser + model-viewer + state sheet | done |
| Search | not built |

## GitHub Pages

Deploy is Actions-only (no `/docs` folder publish). Workflow: `.github/workflows/wiki-pages.yml`.

1. Repo **Settings → Pages → Build and deployment → Source: GitHub Actions** (one-time).
2. Merge this wiring to `main`, or run **Actions → Deploy wiki (GitHub Pages) → Run workflow**.
3. When the deploy job is green, open **https://crowbe.github.io/VerbEndings/**.

Build uses `WIKI_BASE=/VerbEndings/` so asset URLs match project Pages. Locally `npm run dev` still uses `/`. Site-internal links are relative so both modes work.

Symlinked GLBs/art under `wiki/public` need Git LFS on the runner (`lfs: true` in the workflow).
