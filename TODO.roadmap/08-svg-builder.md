# 08 — SvgBuilder

## Status: [x]

## Why

The legacy `Interpreter` emits SVG by string concatenation inline with
execution. This means:

- No central place to enforce XML well-formedness.
- No way to dedup clipPaths / gradients / patterns across the program.
- Hard to test (every operator test has to assert on a fragment).

## Tasks

- [x] `Postsvg::SvgBuilder` — append-only emitter with this surface:
  - `#open_svg(viewbox:, width:, height:)`
  - `#close_svg`
  - `#open_group(transform: nil, clip_path_id: nil, attrs: {})`
  - `#close_group`
  - `#path(d:, fill:, stroke:, stroke_width:, line_cap:, line_join:,
    dash:, clip_path_id:)`
  - `#text(content:, x:, y:, font_family:, font_size:, fill:, attrs:)`
  - `#image(href:, x:, y:, width:, height:, transform:)`
  - `#register_clip_path(d:) -> id` — returns existing id if `d` is
    byte-equal to a previously-registered path.
  - `#register_linear_gradient(...)` / `#register_radial_gradient(...)`
    — same dedup contract.
  - `#register_pattern(...)` — same.
  - `#to_s` — final SVG string.
- [x] XML escaping centralized in `SvgBuilder#escape` (no copy in
  callers).
- [x] All shape/text/gradient methods return `self` so calls chain.
- [x] Deterministic ordering: `<defs>` block emits clipPaths first,
  then gradients, then patterns — sorted by registration order so IDs
  are reproducible.
- [x] The Y-flip wrapper `<g transform="translate(0 H) scale(1 -1)">`
  is the builder's responsibility, not the renderer's. The renderer
  emits shapes in PS-native coordinates; the builder wraps them.

## Determinism invariants

- Two runs of the same input produce byte-equal SVG.
- ID counters start at 1 on every `SvgBuilder.new`.
- Floating-point output goes through `FormatNumber` (see `07`).

## Out of scope

- Byte-exact parity with Ghostscript or any external tool. Postsvg
  produces clean, valid SVG — it does not reproduce another tool's
  formatting quirks (unlike `emfsvg`'s libemf2svg parity goal).
