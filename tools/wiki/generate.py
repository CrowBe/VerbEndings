#!/usr/bin/env python3
"""Generate VerbEndings wiki HTML from docs/art/wiki_catalog.json and docs/wiki/story_sources.json."""

from __future__ import annotations

import html
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "docs/art/wiki_catalog.json"
STORY = ROOT / "docs/wiki/story_sources.json"
WIKI = ROOT / "wiki"
GEN_MARK = "<!-- generated: tools/wiki/generate.py — edit sources, not this file -->"

BADGE = {
    "Integrated Production": "runtime",
    "Production Source": "source",
    "Context Reference": "context",
    "Greybox Contract": "greybox",
    "Partial": "partial",
    "Uncovered": "planned",
}


def esc(s: str) -> str:
    return html.escape(s, quote=True)


def repo_to_public_art(repo_path: str | None) -> str | None:
    """Map docs/art/... paths to wiki/public/art symlink URLs used by the site."""
    if not repo_path:
        return None
    p = repo_path.replace("\\", "/")
    if p.startswith("docs/art/reference_sheets/"):
        return "art/reference_sheets/" + p[len("docs/art/reference_sheets/") :]
    if p.startswith("docs/art/subjects/shared_subject/renders/"):
        return "art/shared_subject_renders/" + p[len("docs/art/subjects/shared_subject/renders/") :]
    if p.startswith("docs/art/subjects/shared_subject/references/"):
        return "art/shared_subject_references/" + p[len("docs/art/subjects/shared_subject/references/") :]
    if p.startswith("docs/art/subjects/shared_subject/meshy_inputs/"):
        return "art/shared_subject_inputs/" + p[len("docs/art/subjects/shared_subject/meshy_inputs/") :]
    if p.startswith("docs/art/material_dispenser/renders/"):
        return "art/material_dispenser_renders/" + p[len("docs/art/material_dispenser/renders/") :]
    if p.startswith("docs/art/material_dispenser_comparison/references/"):
        return "art/material_dispenser_approved/" + p[len("docs/art/material_dispenser_comparison/references/") :]
    if p.startswith("docs/art/intro/flux/"):
        return "art/intro_flux/" + p[len("docs/art/intro/flux/") :]
    if p.startswith("assets/exports/") or p.startswith("assets/source/"):
        # GLBs use public/models symlinks by basename convention in existing pages
        return None
    return None


def glb_public(repo_path: str | None) -> str | None:
    if not repo_path:
        return None
    name = Path(repo_path).name
    # Existing symlinks under wiki/public/models
    mapping = {
        "shared_subject_meshy6b_concept.glb": "models/shared_subject_meshy6b_concept.glb",
        "material_dispenser.glb": "models/material_dispenser.glb",
    }
    return mapping.get(name)


def nav(prefix: str, current: str) -> str:
    items = [
        ("Overview", [
            ("home", "Home", f"{prefix}./" if prefix else "./"),
            ("story", "Story &amp; world", f"{prefix}story/"),
            ("media", "FLUX intro", f"{prefix}media/"),
        ]),
        ("Assets", [
            ("catalog", "Catalog", f"{prefix}assets/"),
            ("sheets", "Reference sheets", f"{prefix}assets/sheets.html"),
            ("subject", "Shared Subject", f"{prefix}assets/shared-subject.html"),
            ("dispenser", "Material Dispenser", f"{prefix}assets/material-dispenser.html"),
        ]),
        ("Sources", [
            ("glossary", "GLOSSARY.md", "https://github.com/CrowBe/VerbEndings/blob/main/GLOSSARY.md"),
            ("world", "WORLD_DESIGN.md", "https://github.com/CrowBe/VerbEndings/blob/main/docs/WORLD_DESIGN.md"),
            ("map", "REFERENCE_ASSET_MAP.md", "https://github.com/CrowBe/VerbEndings/blob/main/docs/art/REFERENCE_ASSET_MAP.md"),
            ("catalog", "wiki_catalog.json", "https://github.com/CrowBe/VerbEndings/blob/main/docs/art/wiki_catalog.json"),
        ]),
    ]
    # fix duplicate key catalog in Sources — rename
    items[2] = (
        "Sources",
        [
            ("glossary", "GLOSSARY.md", "https://github.com/CrowBe/VerbEndings/blob/main/GLOSSARY.md"),
            ("world", "WORLD_DESIGN.md", "https://github.com/CrowBe/VerbEndings/blob/main/docs/WORLD_DESIGN.md"),
            ("map", "REFERENCE_ASSET_MAP.md", "https://github.com/CrowBe/VerbEndings/blob/main/docs/art/REFERENCE_ASSET_MAP.md"),
            ("wcat", "wiki_catalog.json", "https://github.com/CrowBe/VerbEndings/blob/main/docs/art/wiki_catalog.json"),
        ],
    )
    parts = []
    for section, links in items:
        parts.append(f'        <div class="nav-section">{section}</div>')
        for key, label, href in links:
            cur = ' aria-current="page"' if key == current else ""
            parts.append(f'        <a href="{href}"{cur}>{label}</a>')
    return "\n".join(parts)


def shell(title: str, prefix: str, current: str, body: str, css: str, js: str) -> str:
    return f"""<!doctype html>
<html lang="en-AU">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{esc(title)} · VerbEndings Wiki</title>
  <link rel="stylesheet" href="{css}" />
  <script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/4.0.0/model-viewer.min.js"></script>
</head>
<body>
{GEN_MARK}
  <header class="topbar">
    <button type="button" class="nav-toggle" aria-expanded="false" aria-controls="wiki-nav">Menu</button>
    <p class="brand">VerbEndings</p>
  </header>
  <button type="button" class="nav-backdrop" aria-label="Close menu"></button>
  <div class="layout">
    <aside class="sidebar" id="wiki-nav">
      <p class="brand">VerbEndings</p>
      <p class="brand-sub">In-repo game wiki</p>
      <div class="status-pill" title="Systems cyan — normal infrastructure state">Systems nominal</div>
      <nav class="nav" aria-label="Wiki">
{nav(prefix, current)}
      </nav>
    </aside>
    <main class="main">
{body}
    </main>
  </div>
  <script src="{js}" defer></script>
</body>
</html>
"""


def extract_md_section(path: Path, heading: str) -> str:
    text = path.read_text(encoding="utf-8")
    # Match ## Heading at line start
    pattern = rf"(?m)^## {re.escape(heading)}\s*\n"
    m = re.search(pattern, text)
    if not m:
        raise SystemExit(f"heading not found: {path} :: {heading}")
    start = m.end()
    nxt = re.search(r"(?m)^## ", text[start:])
    body = text[start : start + nxt.start()] if nxt else text[start:]
    return body.strip()


def md_inline_to_html(block: str) -> str:
    """Minimal Markdown → HTML for glossary/world excerpts (paragraphs, lists, bold, code, links)."""
    lines = block.splitlines()
    out: list[str] = []
    in_ul = False

    def close_ul():
        nonlocal in_ul
        if in_ul:
            out.append("</ul>")
            in_ul = False

    def inline(s: str) -> str:
        s = esc(s)
        s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
        s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
        s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', s)
        return s

    para: list[str] = []

    def flush_para():
        nonlocal para
        if para:
            out.append("<p>" + inline(" ".join(para)) + "</p>")
            para = []

    for line in lines:
        if line.startswith("### "):
            close_ul()
            flush_para()
            out.append(f"<h3>{inline(line[4:].strip())}</h3>")
        elif re.match(r"^[-*] ", line):
            flush_para()
            if not in_ul:
                out.append('<ul class="prose">')
                in_ul = True
            out.append(f"<li>{inline(line[2:].strip())}</li>")
        elif line.strip() == "":
            close_ul()
            flush_para()
        elif line.startswith("|"):
            # skip tables in spike excerpts (keep simple)
            close_ul()
            flush_para()
        else:
            close_ul()
            para.append(line.strip())
    close_ul()
    flush_para()
    return "\n".join(out)


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    print("wrote", path.relative_to(ROOT))


def gen_home(catalog: dict) -> None:
    n = sum(len(s["assets"]) for s in catalog["sections"])
    body = f"""      <p class="crumb">Wiki</p>
      <h1>VerbEndings wiki</h1>
      <p class="lede">Story, art references, and 3D concept models for VerbEndings — drawn from the project docs and asset packages.</p>
      <div class="token-strip" aria-label="Facility palette from WORLD_DESIGN.md">
        <span class="token-swatch" style="background:#F1EEE6" title="Warm off-white"></span>
        <span class="token-swatch" style="background:#C8CED1" title="Cool light grey"></span>
        <span class="token-swatch" style="background:#66727A" title="Equipment grey"></span>
        <span class="token-swatch" style="background:#273238" title="Charcoal"></span>
        <span class="token-swatch" style="background:#172126" title="Near-black"></span>
        <span class="token-swatch" style="background:#56D6D2" title="Systems cyan"></span>
        <span class="token-swatch" style="background:#F4C95D" title="Safety amber"></span>
        <span class="token-swatch" style="background:#EE625F" title="Alarm coral"></span>
        <span class="token-swatch" style="background:#69C779" title="Validation green"></span>
        <span class="token-swatch" style="background:#F8F4E8" title="Soft white"></span>
      </div>
      <h2>Start here</h2>
      <div class="card-grid">
        <a class="card" href="story/"><div class="body"><span class="badge">Story</span><h3>Story &amp; world</h3><p>Generated from GLOSSARY and WORLD_DESIGN headings.</p></div></a>
        <a class="card" href="assets/"><div class="body"><span class="badge source">Assets</span><h3>Full asset catalog</h3><p>{n} mapped families from wiki_catalog.json.</p></div></a>
        <a class="card" href="media/">
          <img class="sheet" src="art/intro_flux/contact_sheet.png" alt="FLUX intro contact sheet" />
          <div class="body"><span class="badge context">Context Reference</span><h3>FLUX intro</h3><p>Third-pass MP4 from docs/art/intro/flux/.</p></div>
        </a>
        <a class="card" href="assets/sheets.html"><div class="body"><span class="badge partial">Sheets</span><h3>Reference sheets</h3><p>Gallery scanned from docs/art/reference_sheets/.</p></div></a>
      </div>
"""
    write(WIKI / "index.html", shell("Home", "", "home", body, "styles/wiki.css", "nav.js"))


def gen_catalog(catalog: dict) -> None:
    sections_html = []
    count = 0
    for section in catalog["sections"]:
        cards = []
        for a in section["assets"]:
            count += 1
            thumb = repo_to_public_art(a.get("thumb") or a.get("sheet"))
            badge = BADGE.get(a["evidence"], "planned")
            href = f'{a["detail_page"]}.html' if a.get("detail_page") else None
            glb_note = (
                ""
                if a.get("glb")
                else '<p class="meta">No production/concept GLB in catalog yet — reference sheet only.</p>'
            )
            img = (
                f'<img class="sheet" src="../{esc(thumb)}" alt="{esc(a["title"])} reference" loading="lazy" />'
                if thumb
                else ""
            )
            inner = f"""{img}
          <div class="body">
            <span class="badge {badge}">{esc(a["evidence"])}</span>
            <h3>{esc(a["title"])}</h3>
            <p>{esc(a.get("blurb") or "")}</p>
            {glb_note}
          </div>"""
            if href:
                cards.append(f'        <a class="card" href="{href}">\n{inner}\n        </a>')
            else:
                cards.append(f'        <div class="card no-glb">\n{inner}\n        </div>')
        sections_html.append(
            f"""      <section class="family-block">
        <h2>{esc(section["title"])}</h2>
        <p class="lede">Evidence classes from <code>REFERENCE_ASSET_MAP.md</code>. Rows from <code>wiki_catalog.json</code>.</p>
        <div class="card-grid">
{chr(10).join(cards)}
        </div>
      </section>"""
        )
    body = f"""      <p class="crumb"><a href="../">Wiki</a> / Assets</p>
      <h1>Asset catalog</h1>
      <p class="lede">{count} mapped families. Cards show retained reference art even when no GLB exists.</p>
      <p class="callout">Generated sheets are modelling references; they do not by themselves mark an asset production-ready (<code>reference_sheets/README.md</code>).</p>
      <p><a href="sheets.html">Browse reference sheets →</a> · <a href="shared-subject.html">Shared Subject (GLB)</a> · <a href="material-dispenser.html">Material Dispenser (GLB)</a></p>
{chr(10).join(sections_html)}
"""
    write(WIKI / "assets/index.html", shell("Asset catalog", "../", "catalog", body, "../styles/wiki.css", "../nav.js"))


def gen_sheets(catalog: dict) -> None:
    root = ROOT / catalog["sheets_root"]
    files = sorted(root.rglob("*.png"))
    by_dir: dict[str, list[Path]] = {}
    for p in files:
        rel = p.relative_to(root)
        by_dir.setdefault(rel.parts[0], []).append(rel)
    sections = []
    for folder, rels in by_dir.items():
        cards = []
        for rel in rels:
            title = rel.stem.replace("_", " ")
            src = f"../art/reference_sheets/{rel.as_posix()}"
            cards.append(
                f"""        <a class="card" href="{src}" target="_blank" rel="noopener">
          <img class="sheet" src="{src}" alt="{esc(title)}" loading="lazy" />
          <div class="body"><span class="badge partial">{esc(folder)}</span><h3>{esc(title)}</h3></div>
        </a>"""
            )
        sections.append(
            f"""      <section class="family-block">
        <h2>{esc(folder.replace('_', ' '))}</h2>
        <div class="card-grid">
{chr(10).join(cards)}
        </div>
      </section>"""
        )
    body = f"""      <p class="crumb"><a href="../">Wiki</a> / <a href="./">Assets</a> / Reference sheets</p>
      <h1>Generated reference sheets</h1>
      <p class="lede">{len(files)} sheets under <code>{esc(catalog["sheets_root"])}/</code>.</p>
      <p class="callout">See <code>reference_sheets/README.md</code> for use boundary. Generated text or ambiguous geometry is not canon.</p>
{chr(10).join(sections)}
"""
    write(WIKI / "assets/sheets.html", shell("Reference sheets", "../", "sheets", body, "../styles/wiki.css", "../nav.js"))


def gen_media(catalog: dict) -> None:
    media = catalog["media"][0]
    frames = sorted((ROOT / media["frames_dir"]).glob("frame_*.png"))
    frame_html = []
    for f in frames:
        # frame_04s.png → 4
        m = re.search(r"frame_(\d+)s", f.name)
        label = f"{int(m.group(1)):02d}s" if m else f.name
        pub = repo_to_public_art(str(f.relative_to(ROOT)))
        frame_html.append(
            f"""        <figure>
          <img src="../{esc(pub)}" alt="FLUX intro frame at {esc(label)}" loading="lazy" />
          <figcaption>{esc(label)}</figcaption>
        </figure>"""
        )
    poster = repo_to_public_art(media["poster"])
    video = repo_to_public_art(media["path"])
    body = f"""      <p class="crumb"><a href="../">Wiki</a> / FLUX intro</p>
      <h1>{esc(media["title"])}</h1>
      <p class="lede">Context Reference clip retained at <code>{esc(media["path"])}</code>. Not a runtime asset.</p>
      <p class="callout"><span class="badge context">{esc(media["evidence"])}</span> Compound mass, elevated Researcher context, Semantic Engine machinery, and synchronised audio. Dark detail density, adjacent coloured outlets, and permanently Verb-coloured Subjects are not canonical — see <code>WORLD_DESIGN.md</code>.</p>
      <h2>Clip</h2>
      <video class="media-player" controls preload="metadata" poster="../{esc(poster)}">
        <source src="../{esc(video)}" type="video/mp4" />
      </video>
      <p class="source">Disposition: <code>{esc(media["readme"])}</code></p>
      <h2>Contact sheet</h2>
      <p><img src="../{esc(poster)}" alt="FLUX intro contact sheet" style="max-width:100%;border-radius:8px;border:1px solid var(--border)" loading="lazy" /></p>
      <h2>Sample frames</h2>
      <div class="frame-row">
{chr(10).join(frame_html)}
      </div>
"""
    write(WIKI / "media/index.html", shell("FLUX intro", "../", "media", body, "../styles/wiki.css", "../nav.js"))


def gen_story(story: dict) -> None:
    for page in story["pages"]:
        blocks_html = []
        for b in page["blocks"]:
            src = ROOT / b["source"]
            md = extract_md_section(src, b["heading"])
            blocks_html.append(
                f"""      <h2>{esc(b["heading"])}</h2>
      <p class="source">From <code>{esc(b["source"])}</code></p>
      <div class="prose">
{md_inline_to_html(md)}
      </div>"""
            )
        body = f"""      <p class="crumb"><a href="../">Wiki</a> / Story</p>
      <h1>{esc(page["title"])}</h1>
      <p class="lede">{esc(page.get("lede") or "")}</p>
      <p class="source">Assembled by <code>tools/wiki/generate.py</code> from <code>docs/wiki/story_sources.json</code>.</p>
{chr(10).join(blocks_html)}
"""
        out = ROOT / page["out"]
        write(out, shell(page["title"], "../", "story", body, "../styles/wiki.css", "../nav.js"))


def gen_detail_stubs(catalog: dict) -> None:
    """Refresh nav chrome on hand-authored detail pages; leave viewer markup intact if present."""
    # Only rewrite if file exists — keep model-viewer bodies from previous spike
    for a in (x for s in catalog["sections"] for x in s["assets"]):
        if not a.get("detail_page"):
            continue
        path = WIKI / "assets" / f'{a["detail_page"]}.html'
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        if GEN_MARK not in text:
            # mark as hybrid: body hand-tuned, but ensure comment present once
            text = text.replace("<body>", f"<body>\n{GEN_MARK}\n", 1)
        # ensure topbar chrome
        if 'class="topbar"' not in text:
            chrome = """  <header class="topbar">
    <button type="button" class="nav-toggle" aria-expanded="false" aria-controls="wiki-nav">Menu</button>
    <p class="brand">VerbEndings</p>
  </header>
  <button type="button" class="nav-backdrop" aria-label="Close menu"></button>
"""
            text = text.replace("<body>\n", "<body>\n" + chrome, 1)
        if 'id="wiki-nav"' not in text:
            text = text.replace('<aside class="sidebar">', '<aside class="sidebar" id="wiki-nav">', 1)
        if "nav.js" not in text:
            text = text.replace("</body>", '  <script src="../nav.js" defer></script>\n</body>')
        path.write_text(text, encoding="utf-8")
        print("touched", path.relative_to(ROOT))


def main() -> int:
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    story = json.loads(STORY.read_text(encoding="utf-8"))
    gen_home(catalog)
    gen_catalog(catalog)
    gen_sheets(catalog)
    gen_media(catalog)
    gen_story(story)
    gen_detail_stubs(catalog)
    print("ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
