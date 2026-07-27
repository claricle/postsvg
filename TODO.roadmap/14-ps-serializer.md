# 14 — PS Serializer

## Status: [x]

## Why

The SVG→PS direction's last step. Walks a `Model::Program` and emits
PostScript source text. Also used internally by tests for
pretty-printing.

## Tasks

- [x] `Postsvg::Serializer.call(program, eps: false) -> String`.
- [x] Output structure:
  ```
  %!PS-Adobe-3.0 [<eps: EPSF-3.0>]
  %%Creator: Postsvg <version>
  %%BoundingBox: LLX LLY URX URY
  %%HiResBoundingBox: ...    (when sub-integer precision matters)
  %%EndComments
  <body: literal/procedure/operator output>
  showpage
  %%EOF
  ```
- [x] BoundingBox computed by walking the program's path operations
  with the current CTM (a second lightweight pass; the renderer does
  the same walk for SVG viewbox sizing).
- [x] Operator serialization: each `Model::Operator` knows how to emit
  itself via `Serializer::emit_<name>(op, io)`. Same OCP shape as the
  visitor: a new operator adds a method, no switch edits.
- [x] String literal escaping: `( )`, `\\`, `\n`, `\r`, `\t`, octal
  for non-printables. Mirrors PLRM §3.2.2.
- [x] Hex string alternative for binary data: `<DEADBEEF>`.
- [x] Number formatting through `FormatNumber`.
- [x] `eps: true` adds the `EPSF-3.0` header and a `%%EndProlog` /
  `%%Page` block.

## Round-trip guarantee

For the supported subset, `Serializer.call(Parser.parse(
Lexer.tokenize(ps)))` produces output that re-parses to an equivalent
`Model::Program` (modulo formatting). This is the contract the
round-trip spec asserts.

## Out of scope

- Token-stream preservation (comments, whitespace) is not preserved
  across round-trip. Input formatting is normalized.
- Binary PostScript (Level 2 binary object format). Future P3 work.
