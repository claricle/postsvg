# frozen_string_literal: true

module Postsvg
  module Model
    module Literals
      # A PostScript name. +literal:+ distinguishes +/foo+ (literal,
      # pushed onto the stack) from +foo+ (executable, looked up and
      # executed).
      class Name
        attr_reader :value, :literal

        def initialize(value, literal: false)
          @value = value.to_s
          @literal = literal
          freeze
        end

        def literal? = literal
        def executable? = !literal

        def to_s
          @value
        end

        def accept(visitor, ctx)
          visitor.visit_name(self, ctx)
        end

        def ==(other)
          other.is_a?(Name) && other.value == value && other.literal == literal
        end
        alias eql? ==

        def hash
          [value, literal].hash
        end
      end
    end
  end
end
