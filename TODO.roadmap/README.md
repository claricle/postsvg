# Postsvg Roadmap — PS/EPS ⇔ SVG

This directory captures every work item needed to take Postsvg from a
one-directional (PS/EPS → SVG) hand-rolled interpreter to a fully
bidirectional (PS/EPS ⇔ SVG) transformer with a clean, OCP-compliant,
model-driven architecture modelled on `emfsvg`.

Each file is one unit of work. Files are numbered in dependency order;
later files depend on earlier ones unless noted.

## Status legend

- `[ ]` — not started
- `[~]` — in progress
- `[x]` — complete

## Index

| #  | File                                | Priority | Status | Summary                                                       |
|----|-------------------------------------|----------|--------|---------------------------------------------------------------|
| 00 | `00-architecture.md`                | P0       | [x]    | Target architecture and design rationale                      |
| 01 | `01-autoload-migration.md`          | P0       | [x]    | Convert `lib/` to Ruby `autoload`                             |
| 02 | `02-isolate-dormant-code.md`        | P0       | [x]    | Quarantine Parslet/Converter/old SvgGenerator (no deletion)   |
| 03 | `03-domain-model.md`                | P0       | [x]    | `Postsvg::Model::*` typed PS record value objects             |
| 04 | `04-lexer.md`                       | P0       | [x]    | Comment-safe PS lexer producing `Model::Token`s               |
| 05 | `05-parser.md`                      | P0       | [x]    | Token → `Model::Program` (AST with procedure inlining)        |
| 06 | `06-graphics-state.md`              | P0       | [x]    | `Postsvg::GraphicsContext` immutable snapshot + stack         |
| 07 | `07-matrix-and-color.md`            | P0       | [x]    | `Matrix` affine + `Color` RGB/Gray/CMYK value objects         |
| 08 | `08-svg-builder.md`                 | P0       | [x]    | `Postsvg::SvgBuilder` append-only emitter                     |
| 09 | `09-renderer.md`                    | P0       | [x]    | `Postsvg::Renderer` orchestrator for PS→SVG                   |
| 10 | `10-visitor.md`                     | P0       | [x]    | `Postsvg::Visitors::PsVisitor` OCP dispatch                   |
| 11 | `11-operator-coverage.md`           | P1       | [~]    | Comprehensive PS operator coverage (Levels 1/2/3)             |
| 12 | `12-svg-domain.md`                  | P0       | [x]    | `Postsvg::Svg::*` value objects + Nokogiri parser             |
| 13 | `13-translation-handlers.md`        | P0       | [x]    | `Postsvg::Translation::Handlers::*` (SVG → PS, OCP)           |
| 14 | `14-ps-serializer.md`               | P0       | [x]    | `Postsvg::Serializer` Model → PS/EPS source                   |
| 15 | `15-cli-and-public-api.md`          | P0       | [x]    | Finalise `Postsvg.convert/to_ps/from_svg` + CLI               |
| 16 | `16-specs.md`                       | P0       | [~]    | Per-component + round-trip spec coverage                      |
| 17 | `17-docs-sync.md`                   | P1       | [ ]    | README/docs reflect the live pipeline                         |
| 18 | `18-performance-and-determinism.md` | P2       | [ ]    | Frozen-string literals, dedup, deterministic output           |
| 19 | `19-error-model.md`                 | P1       | [ ]    | Typed errors: ParseError / UnsupportedError / SerializeError  |
| 20 | `20-font-and-text.md`               | P2       | [ ]    | Font metrics, glyph outlines, `show`/`ashow`/`widthshow`      |
| 21 | `21-images.md`                      | P2       | [ ]    | `image`/`imagemask` round-trip with PNG encode/decode         |
| 22 | `22-forms-and-resources.md`         | P3       | [ ]    | PS Forms, resource dictionary, `ExecuteForm`                  |
| 23 | `23-level2-level3.md`               | P3       | [ ]    | Shading, patterns, halftone, CID fonts, filters               |
| 24 | `24-ci-and-release.md`              | P2       | [ ]    | Matrix CI, compatibility report, release flow                 |

## Priority key

- **P0** — without this, the bidirectional pipeline does not exist.
- **P1** — meaningful completeness gap (operator coverage, error model).
- **P2** — production hardening (perf, CI, fonts, images).
- **P3** — full PLRM conformance for advanced users.

## What "done" looks like

For 0.2.0 (this roadmap's target):

```ruby
# PS/EPS → SVG (existing direction, rebuilt on clean pipeline)
Postsvg.convert(ps_string)            # => svg string
Postsvg.convert_file(in, out=nil)

# SVG → PS/EPS (new direction)
Postsvg.to_ps(svg_string, eps: false) # => ps string
Postsvg.to_eps(svg_string)            # => eps string
Postsvg.from_svg_file(path, eps: true)
```

```sh
postsvg convert  INPUT.ps|INPUT.eps  [OUTPUT.svg]   # PS/EPS → SVG
postsvg to-ps    INPUT.svg           [OUTPUT.ps]    # SVG → PS
postsvg to-eps   INPUT.svg           [OUTPUT.eps]   # SVG → EPS
postsvg batch    INPUT_DIR           [OUTPUT_DIR]   # auto-detects direction
```

Test coverage: every public method has specs; round-trip
(`SVG → PS → SVG`) preserves geometry for the supported subset.
