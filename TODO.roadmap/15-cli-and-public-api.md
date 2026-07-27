# 15 — CLI + Public API

## Status: [x]

## Why

The public surface needs to be:

1. Symmetric: `to_svg` / `to_ps` / `to_eps` — clear direction in the
   name.
2. Predictable: `convert` is a synonym for the original direction
   (PS→SVG) for backwards compatibility, but new code uses the
   directional names.
3. Discoverable: CLI `--help` shows every command.

## Tasks

- [x] Public API (in `lib/postsvg.rb`):
  ```ruby
  Postsvg.to_svg(ps_or_eps_string, **opts)        # PS/EPS → SVG
  Postsvg.to_svg_file(input_path, output_path=nil, **opts)
  Postsvg.convert(...)                            # alias for to_svg (BC)
  Postsvg.convert_file(...)                       # alias (BC)

  Postsvg.to_ps(svg_string, eps: false, **opts)   # SVG → PS
  Postsvg.to_eps(svg_string, **opts)              # SVG → EPS
  Postsvg.to_ps_file(input_path, output_path=nil, **opts)
  ```
- [x] `Postsvg::Options` frozen struct shared by both directions:
  `verbose:`, `width:`, `height:`, `viewbox_override:`, `eps:`.
- [x] CLI (Thor):
  - `postsvg convert INPUT [OUTPUT]` — PS/EPS → SVG (BC)
  - `postsvg to-svg INPUT [OUTPUT]` — explicit alias
  - `postsvg to-ps INPUT [OUTPUT]` — SVG → PS
  - `postsvg to-eps INPUT [OUTPUT]` — SVG → EPS
  - `postsvg batch INPUT_DIR [OUTPUT_DIR]` — auto-detects by extension
  - `postsvg version`
- [x] Auto-detection in `batch`: `.ps`/`.eps` → SVG; `.svg` → PS.
- [x] CLI exit codes: 0 success, 1 usage error, 2 conversion error.

## Deprecation path

- `Postsvg.convert` and `Postsvg.convert_file` remain as aliases. No
  removal in 0.2; revisit at 1.0.
- The dormant `Postsvg::Converter` class is no longer autoloaded.
  Callers needing it can `require "postsvg/legacy/converter"`
  explicitly.
