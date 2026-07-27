# 11 — Comprehensive PS Operator Coverage

## Status: [~] (P0 subset complete; P1/P2/P3 ongoing)

## Scope

This file is the master list of PS operators we cover. Grouped by
PLRM chapter. Each operator links to its source page in
`../postscript-guide/docs/commands/<category>/index.adoc`.

## Priority P0 (must have for 0.2.0) — DONE

### Stack
- [x] `pop`, `exch`, `dup`, `index`, `roll`, `clear`, `count`

### Arithmetic / math
- [x] `add`, `sub`, `mul`, `div`, `idiv`, `mod`, `neg`, `abs`
- [x] `ceiling`, `floor`, `round`, `truncate`
- [x] `sqrt`, `atan`, `cos`, `sin`, `ln`, `log`, `exp`

### Boolean / bitwise
- [x] `eq`, `ne`, `gt`, `ge`, `lt`, `le`
- [x] `and`, `or`, `xor`, `not`, `bitshift`

### Path construction
- [x] `newpath`, `moveto`, `rmoveto`, `lineto`, `rlineto`
- [x] `curveto`, `rcurveto`, `arc`, `arcn`, `closepath`, `currentpoint`

### Painting
- [x] `stroke`, `fill`, `eofill`, `clip`, `eoclip`

### Color
- [x] `setgray`, `setrgbcolor`, `setcmykcolor`, `sethsbcolor`

### Graphics state
- [x] `gsave`, `grestore`, `setlinewidth`, `setlinecap`,
      `setlinejoin`, `setmiterlimit`, `setdash`

### Transformations
- [x] `translate`, `scale`, `rotate`, `concat`, `matrix`,
      `currentmatrix`, `setmatrix`, `transform`, `dtransform`,
      `itransform`, `idtransform`

### Dictionary / control flow
- [x] `dict`, `begin`, `end`, `def`, `load`, `store`, `known`, `get`,
      `put`
- [x] `if`, `ifelse`, `repeat`, `loop`, `for`, `exit`, `quit`,
      `exec`, `stopped`

### Device
- [x] `showpage`, `copypage`, `nulldevice`

## Priority P1 (0.3.0)

### Strings, arrays, search
- [ ] `length`, `get`, `put`, `getinterval`, `putinterval`, `search`,
      `token`, `anchorsearch`
- [ ] `string`, `substring`, `stringwidth`

### Type / conversion
- [ ] `type`, `cvlit`, `cvx`, `xcheck`, `cvs`, `cvn`, `cvr`, `cvi`,
      `cvrs`

### Files
- [ ] `currentfile`, `read`, `readhexstring`, `readstring`, `closefile`,
      `eof`, `flushfile`

## Priority P2 (0.4.0) — Fonts and text

- [ ] `findfont`, `scalefont`, `setfont`, `show`, `ashow`, `widthshow`,
      `kshow`, `xshow`, `xyshow`, `yshow`, `stringwidth`
- [ ] `FontDirectory`, `StandardEncoding`, `ISOLatin1Encoding`
- [ ] `makefont`, `composefont`, `findencoding`
- [ ] CharPath, Type 3 fonts (rendered via outline procedures)

## Priority P3 (full PLRM)

### Level 2 / 3
- [ ] `image`, `colorimage`, `imagemask` — raster imagery
- [ ] Shading types 1–7 (`shfill`)
- [ ] Patterns: `makepattern`, `setpattern`
- [ ] Forms: `BeginData`, `ExecuteForm`
- [ ] Halftone: `setscreen`, `setcolorscreen`, `sethalftone`
- [ ] CID fonts, Type 0 (composite) fonts
- [ ] Filters: ASCIIHexDecode, ASCII85Decode, LZWDecode, FlateDecode,
      RunLengthDecode, SubFileDecode
- [ ] Binary object format, binary tokens
- [ ] Page device: `setpagedevice`, `currentpagedevice`
- [ ] Resource management: `defineresource`, `findresource`,
      `enumerate`, `resourcestatus`, `undefineresource`
- [ ] `setcolorspace`, `setcolor` (DeviceN, ICCBased)

## Acceptance per operator

- `Model::Operators::<Name>` class with typed operands.
- `from_operands(stack)` factory that pops operands and returns the
  instance.
- `visit_<name>` in `PsVisitor` that mutates the graphics context /
  path builder / svg builder.
- Spec under `spec/postsvg/model/operators/<name>_spec.rb` covering
  operand parsing and visitor side-effects.
- Cross-reference in `docs/postscript/operators/<name>.adoc` (or
  point at the existing page in `../postscript-guide`).
