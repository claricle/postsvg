# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`postsvg` is a pure-Ruby bidirectional converter between PostScript/EPS and SVG. Both directions are implemented in the 0.2.x line; the SVg→PS direction is newer. The PS side uses a hand-written lexer + stack-machine interpreter; the SVG side uses Nokogiri. There is no Ghostscript, Inkscape, or other external renderer.

Code architecture mirrors `emfsvg`: a typed `Model::Program` value object is the single source of truth, with a Renderer / Visitor visiting it to emit SVG, and a Serializer walking it to emit PS.

## Commands

```bash
bundle install                          # set up deps
bundle exec rspec                       # full suite (~74 examples, <0.2s)
bundle exec rspec spec/postsvg/renderer_spec.rb            # one file
bundle exec rspec -e "converts a square PS program to SVG"   # by description
bundle exec rubocop                     # lint (must be clean)
bundle exec rake                        # spec + rubocop (CI gate)

# CLI
bundle exec ruby exe/postsvg convert  INPUT.ps|INPUT.eps  [OUTPUT.svg]
bundle exec ruby exe/postsvg to-svg    INPUT.eps          [OUTPUT.svg]
bundle exec ruby exe/postsvg to-ps     INPUT.svg          [OUTPUT.ps]
bundle exec ruby exe/postsvg to-eps    INPUT.svg          [OUTPUT.eps]
bundle exec ruby exe/postsvg batch     INPUT_DIR         [OUTPUT_DIR]
bundle exec ruby exe/postsvg version
```

## Architecture

```
                ┌─────────────────────┐
PS/EPS bytes ──▶│ Postsvg::Lexer       │
                └──────────┬──────────┘
                           │ tokens
                           ▼
                ┌─────────────────────┐
                │ Postsvg::AstBuilder │
                └──────────┬──────────┘
                           │ Model::Program
                           ▼
          ┌────────────────────────────────┐
          │ Postsvg::Model::Program         │ ── single source of truth
          └────┬─────────────────┬─────────┘
               │ visit           │ emit
               ▼                 ▲
       ┌─────────────────┐       │
       │ Postsvg::       │       │
       │ Renderer +      │       │
       │ PsVisitor +     │       │
       │ SvgBuilder      │       │
       └────────┬────────┘       │
                │                 │
                ▼                 │
        SVG string               │
                │ Nokogiri       │
                ▼                 │
      ┌─────────────────┐         │
      │ Postsvg::       │         │
      │ Svg::Parser     │         │
      └────────┬────────┘         │
               │ Svg::Document   │
               ▼                 │
      ┌─────────────────┐         │
      │ Postsvg::       │         │
      │ Translation::*  │─────────┘
      │ + Serializer    │
      └────────┬────────┘
               ▼
       PS / EPS source
```

MECE responsibilities:

* `Postsvg::Source` (`Lexer`, `AstBuilder`, `OperandStack`) — PS source → typed AST.
* `Postsvg::Model` (`Program`, `Literals::*`, `Operator`) — typed records, immutable value equality.
* `Postsvg::GraphicsContext` / `GraphicsStack` — immutable graphics-state snapshots.
* `Postsvg::Matrix` / `Color` / `FormatNumber` — foundational value types.
* `Postsvg::SvgBuilder` — append-only SVG emitter (dedups clipPaths / gradients).
* `Postsvg::Renderer` + `Postsvg::Visitors::*` — PS → SVG orchestration / dispatch.
* `Postsvg::Svg` (`Parser`, `Element`, `Elements::*`) — SVG domain model.
* `Postsvg::Translation` (`PsRenderer`, `HandlerRegistry`, `Handlers::*`) — SVG → PS dispatch.
* `Postsvg::Serializer` — Model records → PS / EPS source text.
* `Postsvg::CLI` — Thor command-line wrapper.

## Dispatch model

Both directions use an OCP-friendly dispatch via `Model::Operator#accept(visitor, ctx)` for the forward direction and `Translation::HandlerRegistry#handler_for(element)` for the reverse direction.

* **Forward direction**: each `Model::Operator` subclass calls `Operator#register_as(keyword)`, which registers the class in `Model::Operators.@registry` and `define_method(:visit_name)` to route to a `visitor.visit_<name>` method. Adding a new PS operator means writing one class + one `visit_*` method; no switch edits.
* **Reverse direction**: each `Svg::Elements::*` subclass calls `Element.register(tag_name, self)` on load. The `HandlerRegistry` looks up handlers by exact class, then walks the superclass chain so subclassing handlers inherits behaviour. Adding a new SVG element means writing one handler class + one `Element.register` call; no switch edits.

The per-category visitor modules (`lib/postsvg/visitors/ps_visitor/*.rb`) are split by PLRM chapter (Stack, Arithmetic, Boolean, Path, Painting, Color, GraphicsState, Transformations, Dictionary, ControlFlow, Device, Font, Container, Common). Adding a category = new file + `include` line.

## Runtime stack vs AST operands

The visitor maintains its OWN operand stack (`@stack`), separate from the parser's `OperandStack`. Most operators pop from the RUNTIME stack — not the AST — because chained ops like `1 2 add 3 mul` produce `Computed` sentinels at parse time that have no real value. Operators whose AST operands can be `Computed` (arithmetic, boolean, control flow, font, container) MUST pop from runtime:

```ruby
def visit_add(_op, _ctx)
  b = pop_runtime_number
  a = pop_runtime_number
  @stack << a + b
end
```

Operators whose AST operands are always literal-typed at parse time (moveto, setrgbcolor) can use AST operands directly.

The shared helpers (`numeric_value`, `truthy?`, `lookup_dict`, `normalize_key`, `string_value`) live in `PsVisitor::Common` (`lib/postsvg/visitors/ps_visitor/common.rb`) — DRY: previously `normalize_key` was duplicated in Dictionary and Container.

## Source order semantics

`Postsvg::Source::AstBuilder` writes every consumed token — literals and operators — into `Program.body` in source order. This is what the visitor walks. It is NOT just the operators. So `program.body.first` may be a `Number`, not the first operator. This is by design: the visitor must see the literals to populate the operand stack correctly.

## Y-flip and viewbox

PostScript origin is bottom-left; SVG origin is top-left. `Renderer#call` opens the SVG with the viewBox from the DSC header and wraps all shapes in `<g transform="translate(0 H) scale(1 -1)">` so PS-native coordinates produce visually identical output. `SvgBuilder#open_y_flip_group` is the entry point.

When no `%%BoundingBox` is present the renderer falls back to the A4 page size (595×842 pt) from `Options::DEFAULT_PAGE_SIZE`.

## Dispatch gotcha: `private_class_method` and explicit receivers

`Postsvg::Color` has utility class methods (`clamp_byte`, `scale_unit_to_byte`) that look private but are called from inside `initialize` with explicit `Color.clamp_byte(...)`. Marking them private via `private_class_method` causes `NoMethodError: private method 'clamp_byte' called` at load time. **Keep these public.** The project rule forbids `send`, but it's silent on `private_class_method`; we follow the spirit (no privacy barriers) and keep them public.

## Determinism invariants

- Two runs of the same input produce byte-equal output from both directions.
- `SvgBuilder` IDs (`clip1`, `grad1`, `pattern1`) start at 1 on every `SvgBuilder.new`.
- `FormatNumber` is the single source of truth for number formatting.
- No `Time.now`, `SecureRandom`, or `Object#object_id` in IDs.

## Style and code-quality rules

These come from the user's private global `~/.claude/CLAUDE.md` (Code Quality Standards) and are non-negotiable.

- **No `require_relative` in `lib/`** (and no `require` of internal paths either). Use Ruby `autoload` declared in the immediate parent namespace's file (`lib/postsvg.rb` autoloads top-level constants; `lib/postsvg/visitors/ps_visitor.rb` autoloads `PsVisitor::Stack` etc.). The exe (`exe/postsvg`) is allowed to require internal paths.
- **No doubles in specs.** Use real instances or `Struct.new`.
- **No `send` to private methods, no `instance_variable_set/get`, no `respond_to?` for type checks.** For dispatcher "does class define this method?" checks use `self.class.public_method_defined?(method_name)`, not `respond_to?`.
- **No AI attribution** anywhere (commits, PRs, code comments, changelog).
- **Never delete source files.** Legacy Parslet-based files live at their original paths. The current pipeline does not autoload them; they are kept for reference (see `TODO.roadmap/02-isolate-dormant-code.md`).
- **Never commit to `main`, never push tags, never push to `main`.** All changes go through PRs.
- **Library packages have no side effects.** The gem never writes to its own installed location.

## Public API

```ruby
# Forward direction (PS / EPS → SVG)
Postsvg.to_svg(ps_or_eps_string, **opts)
Postsvg.to_svg_file(input_path, output_path=nil, **opts)
Postsvg.convert(...)         # alias for to_svg (BC)
Postsvg.convert_file(...)    # alias (BC)

# Reverse direction (SVG → PS / EPS)
Postsvg.to_ps(svg_string, eps: false, **opts)
Postsvg.to_eps(svg_string, **opts)
Postsvg.to_ps_file(input_path, output_path=nil, eps: false, **opts)
```

Shared `Postsvg::Options` (frozen struct): `eps`, `width`, `height`, `viewbox_override`, `verbose`, `page_size`.

Errors: `Postsvg::ParseError`, `LexError`, `SyntaxError`, `RenderError`, `StackUnderflowError`, `UndefinedOperatorError`, `RecursionLimitError`, `SizeLimitError`, `TranslationError`, `UnsupportedElementError`, `UnresolvedReferenceError`, `SerializeError`. All inherit from `Postsvg::Error`.

## Dependencies

- `parslet`, `thor`, `nokogiri`, `lutaml/canon` (dev only, for XML matcher in integration specs) — see `Gemfile`.

## Limitations

See `README.adoc` and `TODO.roadmap/`. Highlights:

- Real text/font rendering, image round-trip, Level 3 shading, forms are P2 / P3.
- 5 integration specs are currently `pending` (awaiting new-pipeline parity with the legacy SvgBuilder output for `colors.ps`, `example_full.ps`, `file.ps`, `prog.ps`, and `img.ps` / `img.eps`).
