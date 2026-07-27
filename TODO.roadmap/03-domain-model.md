# 03 — PS Domain Model (`Postsvg::Model::*`)

## Status: [x]

## Why

A typed record layer is the backbone of bidirectional conversion:

- The PS→SVG renderer walks records and emits SVG.
- The SVG→PS translator builds records and hands them to the serializer.
- Round-trip tests assert against the record list, not against string
  fragments.

Without a model, every operator is bespoke string manipulation. With a
model, every operator is a value object that participates in equality,
serialization, and dispatch.

## Tasks

- [x] `Model::Token` — lexical token (type, value, position).
  Replaces the bare `Struct` in legacy `Tokenizer`.
- [x] `Model::Number`, `Model::Name`, `Model::StringLiteral`,
  `Model::HexLiteral`, `Model::Array`, `Model::Procedure`,
  `Model::Dictionary` — literal value objects.
- [x] `Model::Program` — root AST node; carries `header` (DSC comments)
  and `body` (statement list).
- [x] `Model::Operators::*` — one class per PS operator
  (see `11-operator-coverage.md` for the full list).
  Each is a frozen `Struct`-like value with:
  - `keyword` — the PS operator name (e.g. `"moveto"`)
  - typed operand fields
  - `accept(visitor, ctx)` — double-dispatch entry point
- [x] Operators grouped by category (`Operators::Path::*`,
  `Operators::Painting::*`, etc.) — MECE by domain, not by file count.

## Operator base class

```ruby
class Model::Operator
  def self.keyword(name)
    define_method(:keyword) { name }
  end

  def accept(visitor, ctx)
    visitor.public_send(:"visit_#{self.class.visit_name}", self, ctx)
  end
end
```

`visitor.visit_moveto(op, ctx)` is public. No `send` to private
methods; the visitor's API is intentionally public.

## Why Struct (not OpenStruct or hand-rolled classes)

- `Struct` gives `==`, `hash`, `members`, `to_h`, and `[]` for free.
- Frozen Structs are immutable value objects.
- Subclassing `Struct.new(...)` works for adding behaviour without
  losing value semantics.

## What goes here vs. `GraphicsContext`

- **Model** = the *program* (what was said).
- **GraphicsContext** = the *interpreter state* (what's true right now
  as the program executes).

The visitor mutates the context; it does not mutate the model.
