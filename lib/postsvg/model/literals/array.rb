# frozen_string_literal: true

module Postsvg
  module Model
    module Literals
      # Bracketed array literal: +[1 2 3]+. Elements may be any
      # literal or operator.
      class ArrayLiteral
        include Enumerable

        attr_reader :elements

        def initialize(elements = [])
          @elements = elements.freeze
          freeze
        end

        def each(&block)
          @elements.each(&block)
        end

        def length = @elements.length
        def empty? = @elements.empty?
        def [](idx) = @elements[idx]

        def accept(visitor, ctx)
          visitor.visit_array(self, ctx)
        end

        def ==(other)
          other.is_a?(ArrayLiteral) && other.elements == @elements
        end
        alias eql? ==

        def hash
          @elements.hash
        end
      end
    end
  end
end
