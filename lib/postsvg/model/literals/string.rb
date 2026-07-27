# frozen_string_literal: true

module Postsvg
  module Model
    module Literals
      # Parenthesized string literal: +(foo bar baz)+.
      class StringLiteral
        attr_reader :value

        def initialize(value)
          @value = value.to_s
          freeze
        end

        def accept(visitor, ctx)
          visitor.visit_string_literal(self, ctx)
        end

        def ==(other)
          other.is_a?(StringLiteral) && other.value == value
        end
        alias eql? ==

        def hash
          value.hash
        end
      end
    end
  end
end
