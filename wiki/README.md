# VerbEndings wiki (spike)

In-repo static wiki for story, art, and 3D concept models. Styled like a game wiki (sidebar + article pages), not a marketing site.

## Run (spike)

```bash
cd wiki
npm install
npm run dev
```

Open the printed local URL. GLBs and art thumbs are symlinked from the repo (`public/models`, `public/art`) — no duplicated binaries.


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
- GitHub Pages / `npm run build` artifact
- Godot `.gdignore` already keeps `assets/source` out of the editor; keep `wiki/dist` gitignored

## Spike coverage

| Page | Status |
| --- | --- |
| Home + sidebar shell | done |
| Story & world (cited excerpts) | done |
| Asset catalog (2 cards) | done |
| Shared Subject + model-viewer (meshy6b) | done |
| Material Dispenser + model-viewer (runtime export) | done |
| Labs / full map / search | not in spike |

## Merge gate

Do not merge until Benjamin OKs this layout. Branch: `docs/wiki-spike`.
