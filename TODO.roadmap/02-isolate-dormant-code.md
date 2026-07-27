# 02 — Isolate dormant code (no deletion)

## Status: [x]

## Why

The repo's first absolute rule is **NEVER DELETE source files**. The
following files exist but are not on the live conversion path:

- `lib/postsvg/converter.rb` (class `Postsvg::Converter`)
- `lib/postsvg/parser.rb` (class `Postsvg::Parser`)
- `lib/postsvg/parser/postscript_parser.rb` (Parslet grammar)
- `lib/postsvg/parser/transform.rb` (Parslet AST transform)
- `lib/postsvg/svg_generator.rb` (class `Postsvg::SvgGenerator`)
- `lib/postsvg/graphics_state.rb` (class `Postsvg::GraphicsState`)
- `lib/postsvg/interpreter.rb` (class `Postsvg::Interpreter` — the
  pre-refactor live path)
- `lib/postsvg/tokenizer.rb` (class `Postsvg::Tokenizer` — pre-refactor
  lexer)

These remain useful as reference material (the dormant Parslet grammar
in particular encodes operator-precedence and syntax insights the new
parser will want to consult). They must NOT be deleted.

## Tasks

- [x] Move these files under `lib/postsvg/legacy/` to make their status
  unambiguous (filesystem move, not deletion; `git mv` preserves
  history).
- [x] Add a module docstring to each: "Legacy implementation, kept for
  reference. Not on the public autoload path."
- [x] Do not declare autoload entries for them in `lib/postsvg.rb`.
- [x] Add a README in `lib/postsvg/legacy/` explaining why they are
  there and how the new pipeline supersedes them.
- [x] Keep their specs (if any) green by adjusting require paths in the
  spec files only — never in the legacy lib files themselves.

## What this is NOT

- Not deletion.
- Not renaming the public classes (the legacy `Postsvg::Converter`
  etc. keep their names; they just live in a different file).
- Not a deprecation cycle with warnings — they are simply not loaded
  by the public API anymore.

## Roll-forward path (future, out of scope)

If/when we want to merge the Parslet grammar's precedence rules into
the new `Parser`, we can do it as a separate refactor that deletes the
`legacy/` directory — at that point it is a deliberate replacement,
not deletion of "unused" code.
