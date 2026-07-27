# 21 — Images

## Status: [ ]

## Why

`image`, `imagemask`, `colorimage` are common in real EPS files (logos,
scanned graphics, illustrations). The legacy `Interpreter` emits a
hardcoded placeholder. The new pipeline must do real work, including
round-trip with SVG `<image>`.

## Scope

### P2a — PS → SVG (decode embedded images)

- [ ] Parse `image` operator: width, height, bits/component,
      matrix, datasource.
- [ ] Decode datasource: hex string `<...>`, binary string `(...)`,
      or proc (rare; emit placeholder).
- [ ] Encode as PNG via `libpng` (same dep `emfsvg` uses) or as inline
      base64 in an SVG `<image href="data:image/png;base64,...">`.
- [ ] `imagemask`: 1-bit mask rendered as an SVG `<image>` with
      opacity or as a clipped fill.
- [ ] `colorimage`: multi-channel variant.

### P2b — SVG → PS (embed images)

- [ ] Resolve `<image href="...">`:
  - `data:` URI → decode base64.
  - file path → read.
  - http(s) → fetch (optional; require explicit opt-in).
- [ ] Decode PNG/JPEG to raw raster.
- [ ] Re-encode as PS hex string for `image` operator.

### P3 — Advanced

- [ ] Subsampling, interpolation, transfer functions.
- [ ] `setcolorspace` with ICCBased profiles.
- [ ] Level 3 image dictionaries (`/ImageType 1`, `/ImageType 4`
      masked images).

## Reference

- PLRM Chapter 7 (Imaging).
- `../postscript-guide/docs/usage/advanced/images.adoc`.
