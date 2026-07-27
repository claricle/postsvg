# 07 — Matrix and Color

## Status: [x]

## Why

Both directions need affine transforms and color conversions. Today
these are spread across `lib/postsvg/matrix.rb` (one good class),
`lib/postsvg/colors.rb` (a module of free functions), and ad-hoc
hex/rgb formatting scattered through the interpreter.

## Tasks

- [x] `Postsvg::Matrix` — already exists and is mostly correct. Keep
  its API; freeze the instance on construction. Add `with(a:, b:, c:,
  d:, e:, f:)` for functional updates so callers never mutate.
- [x] `Postsvg::Color` — value object with `red`, `green`, `blue` in
  `[0, 255]`, plus constructors `Color.rgb`, `Color.gray`,
  `Color.cmyk`, `Color.parse` (CSS `#rrggbb`, `rgb(...)`, named).
- [x] `Color#to_svg` — `"#rrggbb"` or `"rgb(r, g, b)"` based on
  readability (hex by default).
- [x] `Color#to_ps_setrgbcolor` — `"r g b setrgbcolor"` with PS-native
  `[0,1]` floats.
- [x] `Color#to_ps_setgray` — when the color is gray, emit shorter
  `setgray` form.
- [x] Drop the free-function `Colors` module in favour of `Color`
  instances. (The legacy module stays under `legacy/`.)

## Numeric formatting helper

`Postsvg::FormatNumber` — single source of truth for both directions:

- Integers print without trailing `.0`.
- Floats print to 4 decimals, trailing zeros stripped.
- `-0` normalized to `0`.

Replaces the three copies of `num_fmt` in the legacy code.
