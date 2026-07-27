# 17 — Docs Sync

## Status: [ ]

## Why

The README, `docs/architecture.adoc`, and most of `docs/api-reference`
currently describe the dormant Parslet pipeline. The CLAUDE.md flags
this; we need to either:

(a) Update them to describe the live pipeline (preferred).
(b) Clearly mark them as describing a planned pipeline.

(a) wins because users actually consult these docs.

## Tasks

- [ ] README.adoc:
  - Replace "three-stage architecture" diagram with the new pipeline
    diagram (from `00-architecture.md`).
  - Add `Postsvg.to_ps` / `Postsvg.to_eps` examples.
  - Update CLI examples to include `to-ps`, `to-eps`.
  - Update limitations to reflect current actual coverage.
- [ ] docs/architecture.adoc:
  - Describe Lexer / Parser / Model / Renderer / Visitor / SvgBuilder.
  - Describe Svg::* / Translation / Serializer.
  - Add the "MECE responsibility split" table from
    `00-architecture.md`.
- [ ] docs/api-reference.adoc:
  - Per-method yardoc-style entries for the public API.
- [ ] docs/cli-reference.adoc:
  - All commands; auto-detected batch.
- [ ] docs/postscript/svg-mapping.adoc:
  - How each PS operator maps to SVG (one row per operator).
- [ ] docs/postscript/implementation-notes.adoc:
  - The design choices in `00-architecture.md` summarized for users.
- [ ] docs/CHANGELOG.md:
  - 0.2.0 entry with new SVG → PS / EPS direction and breaking
    changes (if any).

## What NOT to touch

- `docs/postscript/operators/*.adoc` — these are content pages, not
  architecture docs. They stay unless an operator's documented
  behaviour changed (it shouldn't).
- `CLAUDE.md` — already accurate; update only if the architecture
  diverges from what it says.
