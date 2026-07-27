# 00 — Architecture

## Status: [x] (this is the design doc; it is the contract for all later files)

## Problem

Postsvg 0.1.0 ships two parallel pipelines:

1. **Live path** (`Postsvg.convert`): raw PS string → hand-written
   `Tokenizer` → `Interpreter#interpret` (a 900-line stack machine that
   emits SVG strings inline via `emit_svg_path`).
2. **Dormant Parslet path**: `Parser::PostscriptParser`,
   `Parser::Transform`, `Converter`, plus an unused `SvgGenerator` and
   `GraphicsState` that are only reached from `Converter`.

The README, gemspec dependency list (`parslet`), and most of `docs/`
describe the dormant Parslet path as if it were live. The live path has
no domain model — every operator reaches into raw hashes and arrays and
mutates them, which makes adding features (let alone a reverse
direction) unsafe.

We need:

- A real **domain model** (typed PS records) so the renderer and the
  serializer can both consume the same data.
- A **renderer** that walks the model and emits SVG via a clean builder.
- A **serializer** that walks the model and emits PS source.
- A **parser** for SVG that produces a parallel `Svg::*` model.
- A **translation** layer that walks the SVG model and produces PS
  records, which the serializer writes out.

All of this must be open for extension (OCP): new PS operator → new
record class + visitor arm; new SVG element → new value class + handler.
Existing code must not change to add new cases.

## Target layering

```
                            ┌─────────────────────┐
                  bytes ───▶│  Postsvg::Lexer     │  comment-aware
                            └──────────┬──────────┘
                                       │ tokens
                                       ▼
                            ┌─────────────────────┐
                            │  Postsvg::Parser    │  AST + proc inlining
                            └──────────┬──────────┘
                                       │ Model::Program
                                       ▼
   ┌──────────────────────────────────────────────────────────────┐
   │  Postsvg::Model::*  (typed PS records, immutable value objs) │
   │   Program, Statement, Procedure, Dictionary, Array, String,  │
   │   Number, Name, operators (Moveto, Lineto, Stroke, …)        │
   └──────────────────────────────────────────────────────────────┘
              │                                          ▲
              │ visit                                    │ emit
              ▼                                          │
   ┌─────────────────────┐                  ┌─────────────────────┐
   │  Postsvg::Renderer  │                  │  Postsvg::Serializer│
   │   + PsVisitor       │                  │   (Model → PS src)  │
   │   + SvgBuilder      │                  │                     │
   └──────────┬──────────┘                  └──────────▲──────────┘
              │ SVG string                             │ Model::Program
              ▼                                        │
   ┌─────────────────────┐                            │
   │  Postsvg::Svg::*    │  parse                     │
   │   Document, Element │────────────┐               │
   └──────────▲──────────┘            │               │
              │                       ▼               │
              │             ┌─────────────────────┐   │
              │             │ Postsvg::Translation│   │
              │             │   PsRenderer        │   │
              │             │   + HandlerRegistry │   │
              │             │   + Handlers::*     │   │
              │             └──────────┬──────────┘   │
              │                        │ Model::Program
              │                        └───────────────┘
              │
              │ round-trip closes here: SVG → Model → SVG
```

## MECE responsibility split

| Namespace                  | Owns                                | Does NOT own                       |
|----------------------------|-------------------------------------|------------------------------------|
| `Postsvg::Lexer`           | PS source → `Model::Token[]`        | semantics, execution               |
| `Postsvg::Parser`          | tokens → `Model::Program`           | rendering, serialization           |
| `Postsvg::Model::*`        | typed records, value equality       | execution, IO                       |
| `Postsvg::GraphicsContext` | CTM, color, clip stack, font        | emitting anything                  |
| `Postsvg::Matrix`          | affine transforms                  | graphics state                     |
| `Postsvg::Color`           | RGB / Gray / CMYK conversions       | mutating state                     |
| `Postsvg::SvgBuilder`      | SVG byte emission, dedup, viewbox   | PS semantics                       |
| `Postsvg::Renderer`        | PS → SVG orchestration              | SVG parsing                        |
| `Postsvg::Visitors::PsVisitor` | dispatch Model record → builder | orchestration                      |
| `Postsvg::Svg::*`          | SVG domain model (parse side)       | PS knowledge                       |
| `Postsvg::Translation::*`  | SVG model → PS Model records       | SVG parsing, PS serialization      |
| `Postsvg::Serializer`      | Model records → PS source text     | SVG                                |
| `Postsvg::CLI`             | argument parsing, IO               | conversion logic                   |

## Constraints (non-negotiable)

These come from the user's global `~/.claude/CLAUDE.md` and from the
project's existing rules:

1. **No `require_relative` in `lib/`.** Use Ruby `autoload` declared in
   the immediate parent namespace file.
2. **No `double()` in specs.** Real instances or `Struct.new`.
3. **No `send` to private methods, no `instance_variable_set`/`get`,
   no `respond_to?` for type checks.**
4. **No AI attribution** anywhere.
5. **Never delete source files.** The dormant Parslet pipeline
   (`Parser`, `Converter`, `SvgGenerator`, `GraphicsState`,
   `parser/postscript_parser.rb`, `parser/transform.rb`) stays in the
   tree under a clearly-marked legacy path; it is no longer on the
   autoload path of the public API.
6. **Never commit to `main`, never push tags, never push to `main`.**
7. **Library packages have no side effects.** No writes to
   `__dir__`/`import.meta.url`-style paths.
8. **DRY / OCP / MECE.** Adding a PS operator or an SVG element must
   not require editing a switch statement; it must be a class + a
   registration.

## What we do NOT do here

- We do not chase byte-exact parity with Ghostscript or Inkscape —
  that is a separate goal and is incompatible with the pure-Ruby,
  no-external-deps constraint.
- We do not implement Level 3 shading, CID fonts, or image filters in
  the P0 / P1 scope. Those are P3.
- We do not delete the Parslet pipeline. It is preserved for reference
  and for any future migration.

## Source materials

- `../postscript-guide/docs/` — operator reference (Levels 1/2/3),
  syntax, data types. Use this for operator semantics, stack effects,
  and edge cases.
- `../emfsvg/` — architectural template (Renderer / Visitor / SvgBuilder
  for forward direction; Svg::Document / Translation::EmfRenderer /
  HandlerRegistry / Handlers::* for reverse direction).
