# 06 — Graphics Context

## Status: [x]

## Why

The legacy code has two graphics-state classes:

- `Postsvg::GraphicsState` — only reached by the dormant `Converter`.
- `@g_state` hash inside `Interpreter` — the live state, untyped.

Neither is reusable for the new pipeline. We need one
direction-agnostic value object that:

- Carries CTM, colors, line style, font, dash pattern, clip stack.
- Is **immutable**; "saving" state pushes a snapshot onto a stack,
  "restoring" pops back to the previous snapshot.
- Does not own SVG/PS-specific emission logic.

## Tasks

- [x] `Postsvg::GraphicsContext` — frozen `Struct`-based value object.
  Fields: `ctm`, `fill_color`, `stroke_color`, `stroke_width`,
  `line_cap`, `line_join`, `miter_limit`, `dash`, `font_name`,
  `font_size`, `clip_stack`, `last_text_position`, `fill_rule`.
- [x] `Postsvg::GraphicsStack` — push/pop of immutable snapshots.
  `grestore` pops; an attempt to pop an empty stack is a no-op (mirrors
  PS spec — `grestore` with empty stack is a no-op).
- [x] Defaults match PLRM defaults: black fill, 1pt stroke, butt cap,
  miter join, miter limit 10, identity CTM, Helvetica 12pt.

## Why immutable

- Snapshots are O(1) reference copies; no deep dup.
- Push/pop cannot accidentally share mutable state across snapshots
  (which was a recurring bug source in the legacy `GraphicsState`
  where `@transform_matrix` was an in-place array).
- Round-trip tests can compare snapshots for equality.

## CoordinateState parallel

`emfsvg` has a `CoordinateState` that is deliberately shared across
`SaveDC`/`RestoreDC` snapshots (GDI quirk). PostScript has no such
quirk — every `gsave`/`grestore` is a full state save — so we do not
need a parallel struct here.
