# frozen_string_literal: true

module Postsvg
  module Model
    module Literals
      # Hex-string literal: +<DEADBEEF>+.
      class HexLiteral
        attr_reader :value

        def initialize(value)
          @value = value.to_s
          freeze
        end

        # Raw bytes encoded by the hex literal.
        def bytes
          hex = value.delete("^0-9a-fA-F")
          hex << "0" if hex.length.odd?
          hex.chars.each_slice(2).map { |pair| pair.join.to_i(16) }.pack("C*")
        end

        def accept(visitor, ctx)
          visitor.visit_hex(self, ctx)
        end

        def ==(other)
          other.is_a?(HexLiteral) && other.value == value
        end
        alias eql? ==

        def hash
          value.hash
        end
      end
    end
  end
end
