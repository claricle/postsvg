# 01 — Migrate `lib/` to Ruby `autoload`

## Status: [x]

## Why

The repo's global rule (see `~/.claude/CLAUDE.md` rule 9) forbids
`require_relative` (and `require` with paths inside the library) in
library code. Reasons: lazy loading, no circular-load crashes, clean
`$LOAD_PATH`, and a single place to read "what does this namespace
expose."

## Tasks

- [x] Define all `autoload` entries for `Postsvg` in `lib/postsvg.rb`.
- [x] Create namespace files for sub-namespaces:
  - `lib/postsvg/model.rb` — `Postsvg::Model` autoloads
  - `lib/postsvg/visitors.rb` — `Postsvg::Visitors` autoloads
  - `lib/postsvg/svg.rb` — `Postsvg::Svg` autoloads
  - `lib/postsvg/translation.rb` — `Postsvg::Translation` autoloads
  - `lib/postsvg/model/operators.rb` — `Postsvg::Model::Operators`
  - `lib/postsvg/svg/elements.rb` — `Postsvg::Svg::Elements`
  - `lib/postsvg/translation/handlers.rb` — `Postsvg::Translation::Handlers`
- [x] Remove every `require_relative` in `lib/` (each file relies on its
  parent namespace's autoload declaration).
- [x] Keep `require "parslet"`, `require "thor"`, `require "nokogiri"`
  in `lib/postsvg.rb` only (external gems).
- [x] Verify `ruby -Ilib -e "require 'postsvg'; Postsvg.convert('...')"`
  still works.

## Rule of thumb

Each `lib/foo/bar/baz.rb` file defines `class Foo::Bar::Baz`. The
*parent* (`lib/foo/bar.rb`) declares `autoload :Baz, "foo/bar/baz"`.
The root (`lib/foo.rb`) declares `autoload :Bar, "foo/bar"`.

This means: never reach across namespaces. If `Baz` needs `Quux`, do
not `require_relative "../quux"` — the parent of `Baz` already
autoloaded `Quux` (or will, when something references it).
