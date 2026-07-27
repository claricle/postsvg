# frozen_string_literal: true

module Postsvg
  module Model
    # Lexical token. Type is one of:
    # +:number+, +:operator+, +:name+, +:string+, +:hexstring+,
    # +:proc_open+, +:proc_close+, +:array_open+, +:array_close+,
    # +:dict_open+, +:dict_close+, +:dsc+.
    #
    # +literal+ is true when a +:name+ was written with a leading slash
    # (i.e. it is a literal name, not an operator-style name reference).
    class Token
      attr_reader :type, :value, :line, :column, :literal

      def initialize(type, value, line: nil, column: nil, literal: false)
        @type = type
        @value = value
        @line = line
        @column = column
        @literal = literal
        freeze
      end

      def position
        [line, column]
      end

      def ==(other)
        other.is_a?(Token) &&
          other.type == @type &&
          other.value == @value &&
          other.line == @line &&
          other.column == @column &&
          other.literal == @literal
      end
      alias eql? ==

      def hash
        [@type, @value, @line, @column, @literal].hash
      end
    end
  end
end
