# 09 — Renderer (PS → SVG orchestrator)

## Status: [x]

## Why

The renderer is the entry point for PS/EPS → SVG. It owns the lifecycle
that the legacy `Interpreter` did, but with clean boundaries:

```
source ──▶ Lexer ──▶ Parser ──▶ Model::Program
                                    │
                                    ▼
                          Renderer#call
                                    │
                       ┌────────────┴───────────┐
                       │ GraphicsStack          │
                       │ PathBuilder            │
                       │ SvgBuilder             │
                       │ PsVisitor              │
                       └────────────┬───────────┘
                                    │
                                    ▼
                                SVG string
```

## Tasks

- [x] `Postsvg::Renderer.call(program, options) -> String`.
- [x] `Renderer::Options` frozen struct: `eps:`, `width:`, `height:`,
  `viewbox_override:`, `verbose:`.
- [x] BoundingBox pre-scan: walk the program once to find any drawing
  outside the declared BoundingBox; if found, expand viewbox or warn.
- [x] Single pass execution: walk `program.body`, dispatch each
  statement via `PsVisitor`, accumulate output in `SvgBuilder`.
- [x] Procedure invocation: when the visitor hits
  `Model::InvokeProcedure`, it descends into the procedure body with
  the current context. Recursion limit (default 64) prevents infinite
  loops from mutually-recursive procedures.
- [x] `MAX_OUTPUT_BYTES` guard (mirrors `emfsvg`): raise
  `RenderError` if output exceeds 100 MB. Pure-Ruby, no memory cap
  enforcement beyond this.

## Why a separate Renderer and Visitor

- The **Renderer** owns lifecycle (open/close SVG, viewbox, options).
- The **Visitor** owns per-record semantics (what does `moveto` do to
  the path builder?).

Splitting them means the Visitor can be unit-tested with a stub
Renderer (a real `SvgBuilder` instance, no double) and reused for any
future "render to non-SVG" target (e.g. an in-memory shape tree).
