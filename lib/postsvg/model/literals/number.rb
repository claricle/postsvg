# frozen_string_literal: true

module Postsvg
  module Model
    module Literals
      # A PostScript numeric literal. Stored as a Ruby Numeric so
      # arithmetic Just Works; class carries the original source
      # representation choice (int vs float) when known.
      class Number
        attr_reader :value

        def initialize(value)
          @value = value.is_a?(Numeric) ? value : Float(value)
          freeze
        end

        def to_i = value.to_i
        def to_f = value.to_f
        def integer? = value.is_a?(Integer)

        def accept(visitor, ctx)
          visitor.visit_number(self, ctx)
        end

        def ==(other)
          other.is_a?(Number) && other.value == value
        end
        alias eql? ==

        def hash
          value.hash
        end
      end
    end
  end
end
