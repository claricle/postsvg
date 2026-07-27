# frozen_string_literal: true

module Postsvg
  module Svg
    module PathData
      # Single SVG path command. Opcode is upper-case (absolute) or
      # lower-case (relative). +args+ is the raw numeric arguments.
      Command = Struct.new(:opcode, :args, keyword_init: true) do
        def absolute? = opcode == opcode.upcase

        def relative? = opcode == opcode.downcase

        def arity
          case opcode.upcase
          when "M", "L", "T" then 2
          when "H", "V" then 1
          when "C" then 6
          when "S", "Q" then 4
          when "A" then 7
          when "Z" then 0
          else 0
          end
        end
      end
    end
  end
end
