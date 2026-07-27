# frozen_string_literal: true

module Postsvg
  module Source
    # Parse-time operand stack. Wraps an Array with type-aware pops.
    class OperandStack
      def initialize
        @items = []
      end

      def push(value)
        @items.push(value)
        self
      end
      alias << push

      def pop
        return Model::Computed.new(operator_keyword: "(missing)") if @items.empty?

        @items.pop
      end

      def pop_number(default_on_empty: nil)
        return default_on_empty if @items.empty? && !default_on_empty.nil?

        value = pop
        return value.to_f if value.is_a?(Model::Literals::Number)
        return value.to_f if value.is_a?(Numeric)

        # Parse-time fallback: a Name (e.g. /x defined via def) or a
        # Computed sentinel (e.g. result of an arithmetic op) cannot
        # be evaluated to a number yet. Return 0 so the operator
        # instance can be built; the visitor will re-resolve at
        # runtime if the program is executed.
        0.0
      end

      def peek(offset = 0)
        @items[-1 - offset]
      end

      def length
        @items.length
      end

      def empty?
        @items.empty?
      end

      def to_a
        @items.dup
      end
    end
  end
end
