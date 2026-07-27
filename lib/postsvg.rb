# frozen_string_literal: true

require "postscript"
require "parslet"
require "thor"
require "nokogiri"

module Postsvg
  autoload :VERSION, "postsvg/version"

  # ============================================================
  # Posts created and managed by the +postscript+ gem.
  # ============================================================
  #
  # `postscript` owns PS source parsing, the typed PS domain model,
  # and the PS source serializer. The `Postscript` namespace is the
  # canonical location; the aliases below keep existing user code
  # working during the transition (deprecated, will be removed at
  # postsvg 1.0).
  #
  # If you maintain postsvg, prefer `Postscript::*` in new code.

  Source       = Postscript::Source
  Model        = Postscript::Model
  Serializer   = Postscript::Serializer
  Matrix       = Postscript::Matrix
  Color        = Postscript::Color
  FormatNumber = Postscript::FormatNumber

  ParseError              = Postscript::ParseError
  LexError                = Postscript::LexError
  SyntaxError             = Postscript::SyntaxError
  StackUnderflowError     = Postscript::StackUnderflowError
  UndefinedOperatorError  = Postscript::UndefinedOperatorError
  RecursionLimitError     = Postscript::RecursionLimitError
  RenderError             = Postscript::RenderError
  SerializeError          = Postscript::SerializeError
  ExitSignal              = Postscript::ExitSignal
  QuitSignal              = Postscript::QuitSignal

  # ============================================================
  # Errors that originate in the SVG side (kept here, not in postscript).
  # ============================================================
  autoload :Error, "postsvg/errors"
  autoload :TranslationError, "postsvg/errors"
  autoload :UnsupportedElementError, "postsvg/errors"
  autoload :UnresolvedReferenceError, "postsvg/errors"

  # Legacy alias for RenderError (postsvg 0.1 API).
  ConversionError = RenderError
  # Legacy alias for UndefinedOperatorError (postsvg 0.1 API).
  UnsupportedOperatorError = UndefinedOperatorError

  # ============================================================
  # Rendering / SVG-side types owned by postsvg.
  # ============================================================
  autoload :GraphicsContext, "postsvg/graphics_context"
  autoload :GraphicsStack, "postsvg/graphics_stack"
  autoload :PathBuilder, "postsvg/path_builder"
  autoload :SvgBuilder, "postsvg/svg_builder"
  autoload :Options, "postsvg/options"
  autoload :Renderer, "postsvg/renderer"
  autoload :Visitors, "postsvg/visitors"
  autoload :Svg, "postsvg/svg"
  autoload :Translation, "postsvg/translation"
  autoload :CLI, "postsvg/cli"

  # Legacy implementations retained on disk for reference. Not on the
  # public autoload path; require explicitly if needed:
  #   require "postsvg/tokenizer"
  #   require "postsvg/interpreter"
  #   require "postsvg/parser"
  #   require "postsvg/converter"
  #   require "postsvg/svg_generator"
  #   require "postsvg/graphics_state"
  #   require "postsvg/colors"

  class << self
    # PS/EPS source -> SVG string.
    def to_svg(source, **options)
      program = Postscript::Source.parse(source)
      Renderer.call(program, Options.new(**options))
    end

    # PS/EPS file -> SVG string. Writes to +output_path+ if given;
    # returns the SVG string either way.
    def to_svg_file(input_path, output_path = nil, **options)
      svg = to_svg(File.read(input_path), **options)
      File.write(output_path, svg) if output_path
      svg
    end

    # SVG string -> PS source. Pass +eps: true+ for EPS output.
    def to_ps(svg_string, eps: false, **options)
      document = Svg::Parser.call(svg_string)
      program = Translation::PsRenderer.call(document, eps: eps)
      Serializer.call(program, eps: eps, **options)
    end

    # SVG string -> EPS source.
    def to_eps(svg_string, **options)
      to_ps(svg_string, eps: true, **options)
    end

    # SVG file -> PS source. Writes to +output_path+ if given.
    def to_ps_file(input_path, output_path = nil, eps: false, **options)
      ps = to_ps(File.read(input_path), eps: eps, **options)
      File.write(output_path, ps) if output_path
      ps
    end

    # Backwards-compatible aliases. Pre-0.2 the only direction was
    # PS -> SVG; existing callers used +convert+ / +convert_file+.
    alias convert to_svg
    alias convert_file to_svg_file
  end
end
