# 10 — PsVisitor (OCP dispatch)

## Status: [x]

## Why

The legacy `Interpreter#execute_operator` is a 50-arm `case op`
statement. Adding a new operator means editing the statement; the OCP
forbids this. The new visitor uses Ruby's `Module#register` /
`Object#const_get` pattern (mirrors `emfsvg`'s `HANDLERS` hash but
uses the model's own double-dispatch so adding an operator is one
class).

## Tasks

- [x] `Postsvg::Visitors::PsVisitor` — `accept`s `Model::Operator`
  subclasses via `op.accept(self, ctx)`. Each operator implements
  `accept` to call `visitor.visit_<name>(self, ctx)`.
- [x] Visitor has one `visit_*` method per operator. Each lives in its
  own file under `lib/postsvg/visitors/ps_visitor/<category>.rb` so
  adding a category is a new file, not an edit.
- [x] Unknown operators (`Model::UnknownOperator`) hit
  `visit_unknown`, which emits an XML comment
  `<!-- unhandled: NAME -->` in verbose mode and is a no-op otherwise.

## Adding a new operator (worked example)

Suppose we want to add `setdash` (already exists; this is just the
shape of the work):

1. Create `lib/postsvg/model/operators/graphics_state/setdash.rb`:
   ```ruby
   class Postsvg::Model::Operators::SetDash < Postsvg::Model::Operator
     keyword "setdash"
     def self.from_operands(stack)
       offset = stack.pop_number
       pattern = stack.pop_array
       new(pattern: pattern, offset: offset)
     end
     attr_reader :pattern, :offset
     def accept(visitor, ctx); visitor.visit_setdash(self, ctx); end
   end
   ```
2. Register in `lib/postsvg/model/operators/graphics_state.rb`:
   `autoload :SetDash, "postsvg/model/operators/graphics_state/setdash"`.
3. Register keyword in
   `lib/postsvg/model/operators/registry.rb`:
   `"setdash" => SetDash`.
4. Implement `visit_setdash` in
   `lib/postsvg/visitors/ps_visitor/graphics_state.rb`.

No existing visitor method changes. No `case` statement edit.

## Performance note

Method dispatch on real Ruby classes is faster than `case op` string
matching. The visitor will be measurably faster than the legacy
interpreter on large files.
