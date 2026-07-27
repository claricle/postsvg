# 19 — Error Model

## Status: [ ]

## Why

Today there is one error class (`Postsvg::Error`) plus three trivial
subclasses. Operators silently swallow bad operands
(`safe_pop_number(0)` returns 0). This makes debugging impossible and
makes the gem unsafe for untrusted input.

## Tasks

- [ ] Typed errors, one per failure mode:
  - `Postsvg::ParseError` — lexer/parser failed.
    - `LexError < ParseError` — bad character / unterminated string.
    - `SyntaxError < ParseError` — unbalanced braces, missing operands.
  - `Postsvg::RenderError` — PS → SVG execution failed.
    - `StackUnderflowError < RenderError`.
    - `UndefinedOperatorError < RenderError` (vs. `UnknownOperator`,
      which is recoverable).
    - `RecursionLimitError < RenderError`.
  - `Postsvg::TranslationError` — SVG → PS failed.
    - `UnsupportedElementError < TranslationError`.
    - `UnresolvedReferenceError < TranslationError` (`url(#missing)`).
  - `Postsvg::SerializeError` — Model → PS failed.
  - `Postsvg::SizeLimitError < RenderError` — exceeded
    `MAX_OUTPUT_BYTES`.
- [ ] All errors carry:
  - `source_position` (line, column) when known
  - `operator_name` when applicable
  - `original` (wrapped exception) when applicable
- [ ] No `rescue StandardError` blanket catches in the public API.
  Catch specific errors; re-raise everything else.
- [ ] Legacy `safe_pop_number(default)` is removed; underflow raises
  `StackUnderflowError`. Operators that legitimately handle missing
  operands (e.g. optional dictionary args) use explicit `stack.maybe_pop`.

## Why typed errors

- Users can catch the specific failure they care about.
- Tests can assert `expect { ... }.to raise_error(ParseError)` without
  matching an unrelated crash.
- The CLI can format different errors differently (syntax error →
  point at file:line; unsupported element → suggest workaround).
