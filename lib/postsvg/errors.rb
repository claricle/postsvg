# frozen_string_literal: true

module Postsvg
  # Base class for every Postsvg error. rescue this to catch anything
  # Postsvg raises.
  class Error < StandardError; end

  # Lexing or parsing failed. Carries +source_position+ when known.
  class ParseError < Error
    attr_reader :source_position

    def initialize(message, source_position: nil)
      @source_position = source_position
      super(message)
    end
  end

  # Lexer hit a character or construct it could not consume.
  class LexError < ParseError; end

  # Tokens did not form a valid PostScript program (unbalanced braces,
  # missing operands, malformed literal).
  class SyntaxError < ParseError; end

  # PS -> SVG execution failed.
  class RenderError < Error
    attr_reader :operator_name

    def initialize(message, operator_name: nil)
      @operator_name = operator_name
      super(message)
    end
  end

  # An operator tried to pop more values than the stack held.
  class StackUnderflowError < RenderError; end

  # An operator referenced a name that has no definition in any
  # active dictionary.
  class UndefinedOperatorError < RenderError; end

  # A procedure invocation chain exceeded the depth limit.
  class RecursionLimitError < RenderError; end

  # Output exceeded the configured byte limit.
  class SizeLimitError < RenderError; end

  # SVG -> PS translation failed.
  class TranslationError < Error
    attr_reader :element_name

    def initialize(message, element_name: nil)
      @element_name = element_name
      super(message)
    end
  end

  # Encountered an SVG element type with no registered handler.
  class UnsupportedElementError < TranslationError; end

  # A reference (clip-path, gradient, pattern) could not be resolved.
  class UnresolvedReferenceError < TranslationError; end

  # Model -> PS source serialization failed.
  class SerializeError < Error; end

  # Legacy aliases kept so older rescue clauses still match.
  ConversionError = RenderError
  UnsupportedOperatorError = UndefinedOperatorError

  # Internal control-flow signals used by the visitor to unwind
  # loops and stop program execution. These are NOT user-facing
  # errors — they are caught by the Renderer.
  class ExitSignal < StandardError; end
  class QuitSignal < StandardError; end
end
