# 22 — Forms and Resources

## Status: [ ]

## Why

PS Forms (Level 2) are cached graphics objects — the PS analogue of
SVG `<defs>` + `<use>`. The SVG→PS direction can naturally emit forms
for repeated subtrees, but this is P3 work.

## Scope

- [ ] `Form resource`: define a form body, register it in a resource
      dictionary, invoke via `execform`.
- [ ] Map SVG `<defs>` + `<use>` to PS Forms.
- [ ] `BeginData` / `EndData` DSC blocks for embedded binary form
      bodies.
- [ ] Form caching: if a form is invoked N times in a program, emit
      the body once and `execform` N times. (Optimization; current
      P0 SVG→PS just inlines.)

## Reference

- PLRM Chapter 8 (Forms and Resources).
- `../postscript-guide/docs/usage/advanced/forms.adoc`.
