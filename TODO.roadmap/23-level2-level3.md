# 23 — PS Level 2 / 3 Coverage

## Status: [ ]

## Why

Real-world EPS files from Illustrator, Inkscape, Ghostscript, and
Adobe tools use Level 2 / 3 features extensively. The 0.2.0 release
covers only the common Level 1 subset. This file tracks the rest.

## Level 2

- [ ] **Color spaces**: `setcolorspace`, `setcolor`, `currentcolorspace`.
  - DeviceGray, DeviceRGB, DeviceCMYK, DeviceN.
  - CIEBasedABC, CIEBasedA.
- [ ] **Patterns**: `makepattern`, `setpattern`. Tiling patterns
      (Type 1) for now; shading patterns under Level 3.
- [ ] **Halftone**: `setscreen`, `setcolorscreen`, `sethalftone`.
- [ ] **Images**: `image` with image dictionary (Level 2 form),
      `imagemask` dictionary form.
- [ ] **Filters**: ASCIIHexDecode, ASCII85Decode, LZWDecode,
      FlateDecode, RunLengthDecode, SubFileDecode, CCITTFaxDecode,
      DCTDecode.
- [ ] **Binary object format / binary tokens**.
- [ ] **Composite fonts** (Type 0): FMapType, Encoding, WMode.
- [ ] **Resource management**: `defineresource`, `findresource`,
      `resourcestatus`, `enumerate`.
- [ ] **Page device**: `setpagedevice`, `currentpagedevice` (paper
      size, duplex, etc.).

## Level 3

- [ ] **Shading** (smooth gradients): types 1-7.
  - `shfill` with ShadingType 1 (Function-based)
  - Type 2 (Axial), Type 3 (Radial) — partial support exists; expand.
  - Type 4 (Free-form Gouraud triangle), Type 5 (Lattice-form Gouraud),
    Type 6 (Coons patch mesh), Type 7 (Tensor-product patch mesh).
- [ ] **Clip paths**: More than one clip path at once; `setclipstrokeparams`.
- [ ] **Image types**: `/ImageType 4` (masked), `/ImageType 3`
      (interleaved).
- [ ] **Transparent imaging**: PDF-in-PS extensions, opacity,
      blending modes.
- [ ] **CIDFont** improvements: vertical metrics, Unicode CMaps.
- [ ] **Chromaticity** (`setchromaticity`).
- [ ] **Paged device** additions: tray selection, install/exit
      procedures.

## Triage

Each unchecked item should become its own roadmap file when prioritized.
For now they are tracked collectively; promote to a numbered file when
scheduled.
