# frozen_string_literal: true

require "parslet"
require "thor"
require "nokogiri"

module Postsvg
  autoload :VERSION, "postsvg/version"

  # Errors
  autoload :Error, "postsvg/errors"
  autoload :ParseError, "postsvg/errors"
  autoload :LexError, "postsvg/errors"
  autoload :SyntaxError, "postsvg/errors"
  autoload :RenderError, "postsvg/errors"
  autoload :StackUnderflowError, "postsvg/errors"
  autoload :UndefinedOperatorError, "postsvg/errors"
  autoload :RecursionLimitError, "postsvg/errors"
  autoload :SizeLimitError, "postsvg/errors"
  autoload :TranslationError, "postsvg/errors"
  autoload :UnsupportedElementError, "postsvg/errors"
  autoload :UnresolvedReferenceError, "postsvg/errors"
  autoload :SerializeError, "postsvg/errors"
  autoload :ConversionError, "postsvg/errors"
  autoload :UnsupportedOperatorError, "postsvg/errors"
  autoload :ExitSignal, "postsvg/errors"
  autoload :QuitSignal, "postsvg/errors"

  # Foundational value types
  autoload :FormatNumber, "postsvg/format_number"
  autoload :Matrix, "postsvg/matrix"
  autoload :Color, "postsvg/color"

  # Source-reading layer (PS source -> Model::Program)
  autoload :Source, "postsvg/source"

  # PS domain model
  autoload :Model, "postsvg/model"

  # Graphics state
  autoload :GraphicsContext, "postsvg/graphics_context"
  autoload :GraphicsStack, "postsvg/graphics_stack"
  autoload :PathBuilder, "postsvg/path_builder"

  # SVG emission (forward direction)
  autoload :SvgBuilder, "postsvg/svg_builder"

  # Forward direction (PS -> SVG)
  autoload :Options, "postsvg/options"
  autoload :Renderer, "postsvg/renderer"
  autoload :Visitors, "postsvg/visitors"

  # SVG domain model (reverse direction input)
  autoload :Svg, "postsvg/svg"

  # Reverse direction (SVG -> PS)
  autoload :Translation, "postsvg/translation"
  autoload :Serializer, "postsvg/serializer"

  # CLI
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
      program = Source.parse(source)
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
