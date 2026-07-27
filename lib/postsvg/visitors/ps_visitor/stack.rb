# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Stack manipulation operator handlers.
      module Stack
        def visit_pop(_op, _ctx)
          pop_value
        end

        def visit_exch(_op, _ctx)
          b = pop_value
          a = pop_value
          @stack << b
          @stack << a
        end

        def visit_dup(_op, _ctx)
          @stack << @stack.last
        end

        def visit_index(op, _ctx)
          @stack << @stack[-1 - op.index]
        end

        def visit_roll(op, _ctx)
          count = op.count
          positions = op.positions
          return if count.abs > @stack.length

          slice = @stack.pop(count)
          rotated = positions.negative? ? slice.rotate(positions) : slice.rotate(-positions)
          rotated.each { |v| @stack << v }
        end

        def visit_clear(_op, _ctx)
          @stack = []
        end

        def visit_count(_op, _ctx)
          @stack << @stack.length
        end
      end
    end
  end
end
