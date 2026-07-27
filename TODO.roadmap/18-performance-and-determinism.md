# 18 — Performance and Determinism

## Status: [ ]

## Why

Pure-Ruby string manipulation can be slow. The legacy `Interpreter`
allocates a new `PathBuilder` on every `reset`; the new pipeline can
do better. Determinism matters for round-trip tests and for
reproducible builds.

## Tasks

- [ ] **Frozen-string literals everywhere.** Add `# frozen_string_literal: true` to every `.rb` file.
- [ ] **`FormatNumber`** is the single source for float formatting.
  Profile with `benchmark-ips` against representative PS files
  (`spec/fixtures/ps2svg/example_full.ps` is the heaviest).
- [ ] **`SvgBuilder`** uses a single `String` accumulator (`String#<<`).
  Avoid `Array#join`.
- [ ] **Dedup registry** uses an interned `String` key (frozen) so
  hash lookup is O(1) with no allocation.
- [ ] **Matrix multiplication** is inlined in `Matrix#multiply` (already
  the case) — no object allocation per component.
- [ ] **Procedure invocation** uses an explicit depth counter rather
  than relying on Ruby's stack (which would `SystemStackError` on
  pathological inputs at ~3000 deep).
- [ ] **GC pressure**: pass `Model::Operator` instances by reference,
  never deep-copy them between passes.
- [ ] **Profiling harness**: `scripts/profile.rb INPUT.ps` runs the
  pipeline under `stackprof` and prints the top 20 hotspots. Useful
  for regression detection.
- [ ] **Memory bound**: `Renderer::MAX_OUTPUT_BYTES` (100 MB default,
  configurable). Raise `RenderError` past this.

## Determinism checklist

- Two runs of the same input → byte-equal output.
- IDs (`clip1`, `grad1`, `pattern1`) start at 1 on every
  `SvgBuilder.new`.
- No `Time.now`, no `SecureRandom`, no `Object#object_id` in IDs.
- No iteration over `Hash` whose order depends on insertion of
  non-deterministic keys.

## Out of scope

- Streaming output (incremental SVG emission for huge files). Future
  work; would require SvgBuilder to expose an `each_chunk` enumerator.
