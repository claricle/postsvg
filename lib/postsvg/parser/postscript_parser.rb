# frozen_string_literal: true

require "parslet"

module Postsvg
  class Parser
    # Parslet-based PostScript parser
    class PostscriptParser < Parslet::Parser
      # Whitespace and comments
      rule(:space) { match('\s').repeat(1) }
      rule(:space?) { space.maybe }
      rule(:comment) do
        str("%") >> (str("\n").absent? >> any).repeat >> str("\n").maybe
      end
      rule(:whitespace) { (space | comment).repeat }
      rule(:whitespace?) { whitespace.maybe }

      # Numbers
      rule(:sign) { match("[+-]") }
      rule(:digit) { match("[0-9]") }
      rule(:integer) do
        (sign.maybe >> digit.repeat(1)).as(:integer)
      end
      rule(:float) do
        (sign.maybe >> digit.repeat(1) >> str(".") >> digit.repeat(1)).as(:float) |
          (sign.maybe >> str(".") >> digit.repeat(1)).as(:float)
      end
      rule(:number) { float | integer }

      # Names (identifiers starting with /)
      rule(:name_char) { match('[a-zA-Z0-9_\-.]') }
      rule(:name) do
        (str("/") >> name_char.repeat(1)).as(:name)
      end

      # Strings (in parentheses, handling escaped characters)
      rule(:string_char) do
        (str("\\") >> any) | (str(")").absent? >> any)
      end
      rule(:string) do
        str("(") >> string_char.repeat.as(:string) >> str(")")
      end

      # Operators and keywords
      rule(:operator_char) { match("[a-zA-Z0-9]") }
      rule(:operator) do
        operator_char.repeat(1).as(:operator)
      end

      # Arrays
      rule(:array) do
        str("[") >> whitespace? >>
          value.repeat.as(:array) >>
          whitespace? >> str("]")
      end

      # Procedures (code blocks in curly braces)
      rule(:procedure) do
        str("{") >> whitespace? >>
          statement.repeat.as(:procedure) >>
          whitespace? >> str("}")
      end

      # Values
      rule(:value) do
        whitespace? >> (
          procedure |
          array |
          string |
          name |
          number |
          operator
        ) >> whitespace?
      end

      # Statements
      rule(:statement) { value }

      # Root rule - a PostScript program is a sequence of statements
      rule(:program) do
        whitespace? >> statement.repeat.as(:program) >> whitespace?
      end

      root(:program)
    end
  end
end
