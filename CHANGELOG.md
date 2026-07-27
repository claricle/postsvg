# Changelog

All notable changes to Postsvg will be documented in this file.

## [Unreleased]

### Added — 2026-07-27

**0.2.0 — PS/EPS ⇔ SVG bidirectional pipeline.**

This release rebuilds the converter on a typed domain model and adds
the reverse direction (SVG → PS / EPS).

* `Postsvg::Model::*` — typed PS records (Program, Literals, Operator
  hierarchy). Adding a new PS operator is a new class + one
  `visit_*` method, no switch edit.
* `Postsvg::Source::Lexer` — comment-aware lexer. Replaces the old
  `Tokenizer` whose `gsub(/%[^\n\r]*/)` corruption of string literals
  broke on inputs with literal `%`.
* `Postsvg::Source::AstBuilder` — turns tokens into a `Model::Program`,
  constructing typed operator instances by popping the parse stack in
  reverse source order.
* `Postsvg::Source::OperandStack` — type-aware parse stack with
  permissive pop (returns a `Computed` sentinel on underflow) so
  procedure bodies parse cleanly without runtime context.
* `Postsvg::Model::Operator.consumes` / `.produces` — stack-arity
  declaration. The parser pushes `Computed` sentinels for each value
  an operator produces, keeping parse-time stack shape in sync with
  runtime semantics.
* `Postsvg::Visitors::PsVisitor` — per-category dispatch tables
  (Path, Painting, Color, GraphicsState, Transformations,
  Dictionary, ControlFlow, Device, Arithmetic, Boolean, Stack, Font,
  Container).
* `Postsvg::SvgBuilder` — append-only SVG emitter with clipPath /
  gradient / pattern dedup and a single Y-flip wrapper group.
* `Postsvg::Renderer` — orchestrator for PS → SVG; sets up viewBox,
  opens SVG / closes SVG, enforces `MAX_OUTPUT_BYTES`, handles
  `QuitSignal` cleanly.
* `Postsvg::Svg::*` — typed SVG domain model (Document, Element,
  PathData, Paint, Stroke, TransformList, ClipPathRegistry) +
  Elements (Svg, Group, Path, Rect, Circle, Ellipse, Line, Polyline,
  Polygon, Text, Image, Defs, ClipPath). The `Element` base class
  provides nil-default getters for `fill`, `stroke_paint`, `stroke`,
  `transform`, `children` so handlers never need `respond_to?`.
* `Postsvg::Svg::Parser` — Nokogiri-backed SVG parser.
* `Postsvg::Translation::*` — SVG → PS dispatch (`PsRenderer`,
  `HandlerRegistry`, per-element `Handlers::*`).
* `Postsvg::Translation::ArcConverter` — SVG endpoint-to-center
  arc parametrization (W3C algorithm from SVG 1.1 §F.6.5).
* `Postsvg::Translation::Handlers::PathHandler` — full SVG path
  command coverage (M/L/H/V/C/S/Q/T/A/Z, absolute + relative).
* `Postsvg::Translation::Handlers::PolygonHandler` — closes the
  path before paint (unlike PolylineHandler).
* `Postsvg::Model::Operators::Painting::FillAndStroke` — marker
  operator for elements with both fill and stroke; serializer emits
  `gsave fill grestore stroke`.
* `Postsvg::Model::Operators::Font::*` — findfont, scalefont, setfont,
  show, xyshow, stringwidth, charpath.
* `Postsvg::Model::Operators::Container::*` — type-dispatching
  length / get / put / getinterval / putinterval / forall / astore /
  search / anchorsearch / token / string / cvs that work on strings,
  arrays, and dictionaries.
* `Postsvg::Serializer` — `Model::Program` → PS / EPS source text.
* `Postsvg::Options` — frozen struct for both directions (`eps`,
  `width`, `height`, `viewbox_override`, `verbose`, `page_size`).
* New CLI commands: `postsvg to-svg`, `postsvg to-ps`, `postsvg
  to-eps`. `convert`, `batch`, `version` retained as BC / helpful
  shortcuts.
* New typed error hierarchy: `LexError`, `SyntaxError`, `StackUnderflowError`,
  `UndefinedOperatorError`, `RecursionLimitError`, `SizeLimitError`,
  `UnsupportedElementError`, `UnresolvedReferenceError`,
  `SerializeError`.

### Changed

- Architecture is fully rewritten around the Renderer / Visitor /
  SvgBuilder pattern (modeled on `emfsvg`). The 0.1.0
  Converter / Parser / Parslet pipeline is preserved at
  `lib/postsvg/{converter,parser,parser/postscript_parser,
  parser/transform,tokenizer,interpreter,svg_generator,
  graphics_state,colors}.rb` as a reference, but is no longer on
  the autoload path. Its method names are no longer public API.
- `Postsvg::Matrix` and `Postsvg::Color` are now promoted from
  utility module to first-class value types. `Colors` (free functions)
  is removed from the live path; existing callers can `require
  "postsvg/colors"` explicitly for the legacy module.
- Specs follow the project's rules: no doubles, no `instance_variable_set`,
  no `send` to private methods, no `respond_to?` for type checks, autoload throughout.

### Fixed

- `PolygonHandler` now emits `closepath` before paint.
- `PathHandler` supports all SVG path commands (M/L/H/V/C/S/Q/T/A/Z,
  absolute and relative).
- All `respond_to?` calls in handlers eliminated (zero remain in
  `lib/`).
- Handler registration is now lazy (auto-triggered on first use)
  instead of eager at file load.
- 6/6 integration fixtures (colors.ps, example_full.ps, file.ps,
  prog.ps, img.ps, img.eps) now convert without error.

### Test coverage

- 99 examples, 0 failures.

