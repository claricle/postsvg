# 04 — PS Lexer (`Postsvg::Lexer`)

## Status: [x]

## Why

The legacy `Tokenizer` strips comments with a global
`gsub(/%[^\n\r]*/, " ")` *before* tokenizing. This corrupts `%`
characters inside string literals (`(100% off)` becomes `(100 off)`).

The new lexer must:

- Be comment-aware: distinguish `%` starting a line comment from `%`
  inside `(...)` strings and `<...>` hex strings.
- Carry source positions (line, column) for error messages.
- Emit `Model::Token` value objects, not bare `Struct`s.
- Never mutate the input.

## Tasks

- [x] `Lexer.tokenize(source) -> [Model::Token]` — public entry.
- [x] State machine with these states:
  - `:top` — normal scanning
  - `:string` — inside `(...)`, tracks nesting, honours `\` escapes
  - `:hexstring` — inside `<...>`, stops at `>`
  - `:line_comment` — from `%` to end of line, but only when in `:top`
- [x] Token types: `:number`, `:name` (with leading `/` stripped,
  stored as a `Name` literal flag), `:operator`, `:string`,
  `:hexstring`, `:proc_open`, `:proc_close`, `:array_open`,
  `:array_close`, `:dict_open`, `:dict_close`.
- [x] Numeric scanner handles: integers, decimals, leading-dot,
  trailing-dot, scientific notation, leading sign.
- [x] DSC comments (`%%BoundingBox:` etc.) are captured as a special
  `:dsc` token so the parser can extract header metadata without
  re-parsing source.

## Out of scope

- Binary tokens (Level 2 binary object format). Future work; tracked
  in `23-level2-level3.md`.
