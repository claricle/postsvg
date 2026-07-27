# frozen_string_literal: true

module Postsvg
  module Source
    # Comment-aware PS lexer.
    #
    # Distinguishes +#+ line comments from +%+ inside string literals,
    # captures DSC comments (lines beginning with +%%+), and tags every
    # token with its source position (line, column).
    #
    # The legacy Tokenizer stripped comments with a global
    # +gsub(/%[^\n\r]*/, " ")+ before lexing, which corrupted +%+ chars
    # inside string literals. This implementation walks the source as a
    # state machine so +%+ inside (...) or <...> survives.
    class Lexer
      attr_reader :source, :position, :line, :column

      def initialize(source)
        @source = source.to_s
        @position = 0
        @line = 1
        @column = 1
        @tokens = []
        @state = :top
      end

      def tokenize
        until eos?
          case @state
          when :top        then scan_top
          when :string     then scan_string_body
          when :hexstring  then scan_hexstring_body
          when :comment    then scan_comment_body
          when :dsc        then scan_dsc_body
          end
        end
        @tokens.freeze
      end

      def self.tokenize(source)
        new(source).tokenize
      end

      private

      def eos? = @position >= @source.bytesize

      def peek(offset = 0)
        @source.getbyte(@position + offset)
      end

      def advance
        byte = @source.getbyte(@position)
        @position += 1
        if byte == 10 # \n
          @line += 1
          @column = 1
        else
          @column += 1
        end
        byte
      end

      def scan_top
        skip_whitespace and return
        byte = peek
        return if byte.nil?

        char = byte.chr

        case char
        when "%"        then start_dsc_or_comment
        when "("        then start_string
        when "<"
          if peek(1) == 60 # <<
            advance
            advance
            emit(:dict_open, "<<")
          else
            start_hexstring
          end
        when ">"        then maybe_close_dict
        when "{"        then advance and emit(:proc_open, "{")
        when "}"        then advance and emit(:proc_close, "}")
        when "["        then advance and emit(:array_open, "[")
        when "]"        then advance and emit(:array_close, "]")
        when "/", "\\"
          start_name_with_slash(char)
        else
          scan_word_or_number
        end
      end

      def skip_whitespace
        consumed = false
        until eos?
          byte = peek
          break unless whitespace_byte?(byte)

          advance
          consumed = true
        end
        consumed
      end

      def whitespace_byte?(byte)
        byte && [32, 9, 10, 13, 12, 11, 0].include?(byte)
      end

      def start_dsc_or_comment
        advance # consume first %
        if peek == 37 # second %
          advance # consume second %
          @state = :dsc
        else
          @state = :comment
        end
      end

      def scan_dsc_body
        start_pos = @position
        start_line = @line
        start_col = @column
        until eos? || @source.getbyte(@position) == 10
          advance
        end
        text = @source.byteslice(start_pos, @position - start_pos)
        @tokens << Model::Token.new(:dsc, text.chomp, line: start_line, column: start_col)
        @state = :top
      end

      def scan_comment_body
        until eos? || @source.getbyte(@position) == 10
          advance
        end
        @state = :top
      end

      def start_string
        start_line = @line
        start_col = @column
        advance # consume (
        @string_start = { line: start_line, column: start_col, bytes: +"" }
        @string_depth = 1
        @state = :string
      end

      def scan_string_body
        until eos?
          byte = @source.getbyte(@position)
          case byte
          when 92 # backslash
            advance
            handle_escape
          when 40 # (
            advance
            @string_depth += 1
            @string_start[:bytes] << "("
          when 41 # )
            advance
            @string_depth -= 1
            if @string_depth.zero?
              emit_string
              return
            end
            @string_start[:bytes] << ")"
          else
            advance
            @string_start[:bytes] << byte.chr
          end
        end
        raise LexError.new("unterminated string literal",
                           source_position: [@string_start[:line], @string_start[:column]])
      end

      def handle_escape
        byte = peek
        return if byte.nil?

        char = byte.chr
        replacement =
          case char
          when "n"  then "\n"
          when "r"  then "\r"
          when "t"  then "\t"
          when "b"  then "\b"
          when "f"  then "\f"
          when "\\" then "\\"
          when "("  then "("
          when ")"  then ")"
          when "0".."7"
            consume_octal_escape
          else
            char
          end
        if replacement.is_a?(String)
          advance
          @string_start[:bytes] << replacement
        end
      end

      def consume_octal_escape
        digits = +""
        3.times do
          byte = peek
          break unless byte && (byte >= 48 && byte <= 55) # 0..7

          digits << byte.chr
          advance
        end
        code = digits.to_i(8) & 0xFF
        @string_start[:bytes] << code.chr
        nil
      end

      def emit_string
        @tokens << Model::Token.new(:string, @string_start[:bytes],
                                    line: @string_start[:line], column: @string_start[:column])
        @string_start = nil
        @state = :top
      end

      def start_hexstring
        start_line = @line
        start_col = @column
        advance # consume <
        @hex_start = { line: start_line, column: start_col, bytes: +"" }
        @state = :hexstring
      end

      def scan_hexstring_body
        until eos?
          byte = @source.getbyte(@position)
          case byte
          when 62 # >
            advance
            emit_hexstring
            return
          when 32, 9, 10, 13, 12
            advance
          else
            advance
            @hex_start[:bytes] << byte.chr
          end
        end
        raise LexError.new("unterminated hex string literal",
                           source_position: [@hex_start[:line], @hex_start[:column]])
      end

      def emit_hexstring
        hex = @hex_start[:bytes].delete("^0-9a-fA-F")
        @tokens << Model::Token.new(:hexstring, hex,
                                    line: @hex_start[:line], column: @hex_start[:column])
        @hex_start = nil
        @state = :top
      end

      def maybe_close_dict
        if peek(1) == 62 # >>
          advance
          advance
          emit(:dict_close, ">>")
        else
          # Lone '>' is not a valid token in PS; skip and warn via token.
          advance
        end
      end

      def start_name_with_slash(prefix)
        start_line = @line
        start_col = @column
        advance
        bytes = +""
        until eos?
          byte = peek
          break if byte.nil? || whitespace_byte?(byte) || delimiter_byte?(byte)

          bytes << byte.chr
          advance
        end
        @tokens << Model::Token.new(:name, bytes, line: start_line, column: start_col, literal: true)
      end

      def delimiter_byte?(byte)
        return false unless byte

        char = byte.chr
        "%()<>{}/[]".include?(char)
      end

      def scan_word_or_number
        start_line = @line
        start_col = @column
        bytes = +""
        until eos?
          byte = peek
          break if byte.nil? || whitespace_byte?(byte) || delimiter_byte?(byte)

          bytes << byte.chr
          advance
        end
        emit_word(bytes, start_line, start_col)
      end

      def emit_word(bytes, line, col)
        type =
          if NUMBER_RE.match?(bytes)
            :number
          else
            :operator
          end
        @tokens << Model::Token.new(type, bytes, line: line, column: col)
      end

      NUMBER_RE = /\A[-+]?(?:\d+\.\d*|\.\d+|\d+)(?:[eE][-+]?\d+)?\z/.freeze

      def emit(type, value)
        @tokens << Model::Token.new(type, value, line: @line, column: @column)
      end
    end
  end
end
