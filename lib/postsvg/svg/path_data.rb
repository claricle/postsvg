# frozen_string_literal: true

module Postsvg
  module Svg
    # Parses the SVG path "d" attribute into a list of Command value
    # objects. Each Command carries its opcode (M, L, C, Z, A, etc.)
    # and its numeric arguments.
    module PathData
      autoload :Command, "postsvg/svg/path_data/command"
      autoload :Parser, "postsvg/svg/path_data/parser"

      def self.parse(text)
        Parser.parse(text)
      end
    end
  end
end
