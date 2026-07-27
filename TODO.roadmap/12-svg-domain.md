# 12 — SVG Domain Model (`Postsvg::Svg::*`)

## Status: [x]

## Why

The SVG→PS direction needs a typed intermediate, parallel to
`Postsvg::Model::*` on the PS side. Consuming raw Nokogiri nodes would
couple every translator to libxml2 quirks; building value objects up
front gives us:

- Stable equality for round-trip tests.
- A clean place to attach SVG-specific semantics (`paint`,
  `stroke-dasharray`, `clip-path` reference resolution).
- A registration point for the OCP handler dispatch.

The shape is borrowed directly from `emfsvg/lib/emfsvg/svg/*`.

## Tasks

- [x] `Postsvg::Svg::Parser.call(svg_string) -> Svg::Document`.
- [x] `Postsvg::Svg::Document` — carries `root_element`, `viewbox`,
  `width`, `height`, `clip_paths` registry (built from `<defs>`).
- [x] `Postsvg::Svg::Element` — base class with:
  - `ELEMENT_NAME` constant
  - `children`, `clip_path`, `transform`
  - `self.register(name, subclass)` — populates a class-level registry
  - `self.from_node(node)` — dispatches to registered subclass, falls
    back to `OpenElement` so unknown tags descend into children
- [x] Elements (P0 set):
  - `Svg::Elements::Svg` (root)
  - `Svg::Elements::Group`
  - `Svg::Elements::Path`
  - `Svg::Elements::Rect`
  - `Svg::Elements::Circle`
  - `Svg::Elements::Ellipse`
  - `Svg::Elements::Line`
  - `Svg::Elements::Polyline`
  - `Svg::Elements::Polygon`
  - `Svg::Elements::Text` (+ `Tspan`)
  - `Svg::Elements::Image`
  - `Svg::Elements::Defs`
  - `Svg::Elements::ClipPath`
  - `Svg::Elements::LinearGradient`, `Svg::Elements::RadialGradient`
- [x] Value objects for cross-cutting concepts:
  - `Svg::Color` — wraps `Postsvg::Color`
  - `Svg::Paint` — solid color, `url(#id)` reference, or `none`
  - `Svg::Stroke` — width, dasharray, dashoffset, linecap, linejoin,
    miterlimit
  - `Svg::PathData::Command` — single SVG path command; `PathData`
    parses the `d` attribute into an array of commands
  - `Svg::TransformList` — parses `transform="..."` into a list of
    `Matrix` instances
- [x] `Svg::ClipPathRegistry.from_document(doc)` — indexes
  `<clipPath id="…">` definitions by id for handler lookup.

## Out of scope

- CSS stylesheet parsing. SVG `<style>` blocks are not interpreted;
  presentation attributes only. (Future work; tracked in
  `23-level2-level3.md`.)
- Animation elements (`<animate>`, `<animateTransform>`). Skipped.
