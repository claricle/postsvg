# 20 — Fonts and Text

## Status: [ ]

## Why

The legacy `Interpreter` emits a stub `<text>` element from `show`,
which is not even close to correct — PS fonts have metrics, kerning,
encoding, and often glyph-specific procedures. For the SVG→PS
direction, mapping `<text>` back to PostScript `show` requires a font
the target device knows about.

## Scope by priority

### P2a — Names and basic show (0.4.0)

- [ ] Built-in PS font registry: Courier, Helvetica, Times-Roman +
      oblique/bold variants. Map SVG generic families (`serif`,
      `sans-serif`, `monospace`) to these.
- [ ] `findfont` / `scalefont` / `setfont` parsing in the PS direction.
- [ ] `show` / `stringwidth` operators (without kerning).
- [ ] SVG `<text>` → PS: emit `findfont`, `scalefont`, `setfont`,
      `moveto`, `show`.

### P2b — Outline text (0.5.0)

- [ ] For fonts whose metrics we know (Helvetica, Courier, Times),
      convert `<text>` to outlines (path operations) for fidelity.
      Optional flag: `Postsvg.to_svg(ps, text_mode: :outlines)`.
- [ ] `charpath` operator.

### P3 — Full font machinery

- [ ] Type 1 font parsing (`.pfa` / `.pfb`).
- [ ] Type 3 font procedures (rendered via their PaintProc).
- [ ] CID fonts (composite, vertical writing modes).
- [ ] `ashow`, `widthshow`, `kshow`, `xshow`, `xyshow`, `yshow`.
- [ ] Encoding vectors: `StandardEncoding`, `ISOLatin1Encoding`,
      custom encodings via `defineencoding`.

## Reference

- `../postscript-guide/docs/commands/font-text/index.adoc` — operator
  reference.
- `../postscript-guide/docs/usage/advanced/fonts-text.adoc` — tutorial.
- PLRM Chapter 5 (Fonts) and Chapter 9 (Typesetter's Model).
