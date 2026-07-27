# 16 — Specs

## Status: [~]

## Why

Per the global rule: "Good specs throughout. Every public method
should have specs. Every behavioral edge case should be covered.
Specs use real model instances — never doubles."

## Layout

```
spec/
├── spec_helper.rb
├── postsvg_spec.rb               # public API contract
├── postsvg/
│   ├── lexer_spec.rb             # token-by-token
│   ├── parser_spec.rb            # AST shape, DSC capture
│   ├── model/
│   │   ├── program_spec.rb
│   │   ├── token_spec.rb
│   │   └── operators/
│   │       ├── stack_spec.rb
│   │       ├── arithmetic_spec.rb
│   │       ├── path_spec.rb
│   │       └── ...               # one per operator category
│   ├── graphics_context_spec.rb
│   ├── matrix_spec.rb
│   ├── color_spec.rb
│   ├── svg_builder_spec.rb
│   ├── renderer_spec.rb          # PS → SVG
│   ├── visitors/
│   │   └── ps_visitor_spec.rb
│   ├── svg/
│   │   ├── parser_spec.rb
│   │   ├── document_spec.rb
│   │   └── elements/
│   │       └── *_spec.rb
│   ├── translation/
│   │   ├── handler_registry_spec.rb
│   │   ├── ps_renderer_spec.rb
│   │   └── handlers/
│   │       └── *_spec.rb
│   ├── serializer_spec.rb
│   ├── cli_spec.rb
│   └── integration_spec.rb       # full-pipeline + fixtures
├── round_trip_spec.rb            # SVG → PS → SVG
└── fixtures/
    ├── ps2svg/                   # existing fixtures (kept)
    ├── eps2svg/                  # existing fixtures (kept)
    ├── svg2ps/                   # new: SVG → PS inputs + expected
    └── round_trip/               # new: SVG ↔ PS pairs
```

## Tasks

- [x] Each `Model::Operators::*` class has a spec for:
  - `from_operands` parsing (correct pops, error on stack underflow)
  - value equality
- [x] Each `Svg::Elements::*` class has a spec for `from_node`
  (parses attributes correctly, drops nothing silently).
- [x] Each `Translation::Handlers::*` has a spec that builds a minimal
  SVG element, runs the handler against a real `Context` (no double),
  and asserts on the emitted `Model::Program` records.
- [x] `SvgBuilder` spec covers dedup (two identical clipPaths → one
  `<defs>` entry) and XML escaping.
- [x] `Serializer` spec round-trips: serialize → lex → parse →
  equality with original `Model::Program`.
- [x] `Renderer` spec covers PS→SVG for each fixture in
  `spec/fixtures/ps2svg/` and `spec/fixtures/eps2svg/`.
- [x] `Cli` spec uses `StringIO` capture of stdout; writes inputs to
  `Dir.tmpdir`; cleans up.
- [x] `Round-trip` spec: for each SVG in `spec/fixtures/round_trip/`,
  `to_ps` then `to_svg` and assert geometric equivalence (within 1px
  tolerance; uses `Canon` matcher configured in spec_helper).

## Anti-patterns banned

- `double(...)`, `instance_double(...)`, `allow_any_instance_of`.
- Mocking the file system with `FakeFS`. Use `Dir.tmpdir`.
- Mocking time. Pass `Time.at(fixed)` to constructors that need it.
- `subject { described_class }` with implicit receiver — explicit
  `expect(described_class.foo).to ...`.
