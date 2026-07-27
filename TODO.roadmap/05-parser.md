# 05 — PS Parser (`Postsvg::Parser`)

## Status: [x]

## Why

Turn the token stream into a typed `Model::Program`. The legacy
`Interpreter` mixed lexing, parsing, and execution in one pass; we
separate them so that:

- The renderer can pre-scan for `%%BoundingBox`, `%%Pages`, etc.
- The serializer can walk a typed AST.
- Tests can assert on the AST, not on side effects.

## Tasks

- [x] `Parser.parse(tokens) -> Model::Program`.
- [x] Procedure bodies (`{ ... }`) become `Model::Procedure` nodes
  carrying nested tokens — *not* flattened into the stream.
- [x] Arrays (`[ ... ]`) become `Model::Array` literals.
- [x] Dictionaries (`<< ... >>`) become `Model::Dictionary` literals.
- [x] DSC comments (`%%BoundingBox:`, `%%Title:`, `%%Pages:`, etc.)
  populate `Model::Program#header`.
- [x] Operator dispatch: when an operator token is consumed, pop the
  right number of operands off an internal parse stack and construct
  the corresponding `Model::Operators::*` instance. *Unknown*
  operators stay as `Model::UnknownOperator` so the visitor can warn
  rather than crash.
- [x] PostScript's `def` defines names that may later be referenced as
  operators. The parser records these in a `definitions` map; on
  encountering a bare name that resolves to a `Model::Procedure`, it
  emits a `Model::InvokeProcedure` node carrying the procedure body.

## Design choice: do we inline procedures?

The legacy `Interpreter` splices procedure tokens back into the token
stream (`tokens.insert(current_index + 1, *proc_tokens)`). This is
fast but loses structure.

The new parser keeps procedures as values; the **renderer** is
responsible for descending into them when they are invoked. This makes
the AST stable across passes (useful for the renderer's bounding-box
pre-scan) and lets the serializer emit procedures verbatim.
