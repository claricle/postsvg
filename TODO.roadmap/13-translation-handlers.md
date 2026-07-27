# 13 — Translation Handlers (SVG → PS)

## Status: [x]

## Why

The SVG → PS direction is the mirror of the PS → SVG renderer. Where
the renderer walks PS records and emits SVG, the translator walks SVG
elements and emits PS records. The records are then serialized by
`Postsvg::Serializer`.

The handler-per-element pattern (mirrors `emfsvg`'s
`Translation::Handlers::*`) keeps the dispatch OCP: new SVG element
type → new handler class + registration, no switch.

## Tasks

- [x] `Postsvg::Translation::PsRenderer` — top-level orchestrator.
  Takes `Svg::Document`, returns `Model::Program`.
- [x] `Postsvg::Translation::HandlerRegistry` — element class →
  handler class. Walks superclass chain so subclassing handlers
  inherits behaviour.
- [x] `Postsvg::Translation::Context` — carries:
  - `program` (the `Model::Program` being built)
  - `graphics_stack` (mirrors renderer's)
  - `clip_path_registry` (resolved references)
  - `serializer_options` (eps:, page_size:)
- [x] `Postsvg::Translation::RecordEmitter` — thin helper that appends
  `Model::Operator` instances to `program.body` in source order.
- [x] Handlers (P0 set):
  - `Handlers::SvgHandler` — emits header: `%%BoundingBox`,
    `newpath`, set up Y-flip
  - `Handlers::GroupHandler` — `gsave`, transform concat, descend,
    `grestore`
  - `Handlers::PathHandler` — converts `PathData` commands to PS
    `moveto`/`lineto`/`curveto`/`closepath`, then `stroke`/`fill`
    based on `paint-*` attributes
  - `Handlers::RectHandler` — synthesizes path: `newpath`,
    `x y moveto`, `w 0 rlineto`, `0 h rlineto`, `-w 0 rlineto`,
    `closepath`
  - `Handlers::CircleHandler` — `arc`
  - `Handlers::EllipseHandler` — `scale` + `arc` + restore
  - `Handlers::LineHandler` — `moveto`, `lineto`, `stroke`
  - `Handlers::PolylineHandler` / `Handlers::PolygonHandler` —
    walk points
  - `Handlers::TextHandler` — `findfont`/`scalefont`/`setfont`,
    `moveto`, `show`
  - `Handlers::ImageHandler` — emit `image` with `datasource`
    (PNG bytes hex-encoded; full image support is P2)
  - `Handlers::DefsHandler` — registers but does not paint
  - `Handlers::ClipPathHandler` — defines clip via `clippath`/`clip`

## Handler contract

```ruby
class Handlers::PathHandler
  def self.call(element, context)
    # 1. Update graphics context from element's paint/stroke/transform.
    # 2. Emit Model records (moveto/lineto/...).
    # 3. Emit terminal operator (stroke/fill/clip).
    # 4. Recurse into children if any.
  end
end
```

Handlers never touch the serializer directly. They build `Model::*`
records; the serializer consumes them later. This keeps the model the
single source of truth and enables future PS → PS transformations
(optimization, validation) without re-parsing.
