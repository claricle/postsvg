# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Boolean / comparison operator handlers. Pop from RUNTIME stack
      # so chained comparisons behave correctly.
      module Boolean
        def visit_true(_op, _ctx)
          @stack << true
        end

        def visit_false(_op, _ctx)
          @stack << false
        end

        def visit_eq(_op, _ctx)
          b = @stack.pop
          a = @stack.pop
          @stack << (a == b)
        end

        def visit_ne(_op, _ctx)
          b = @stack.pop
          a = @stack.pop
          @stack << (a != b)
        end

        def visit_gt(_op, _ctx)
          b = pop_runtime_number
          a = pop_runtime_number
          @stack << (a > b)
        end

        def visit_ge(_op, _ctx)
          b = pop_runtime_number
          a = pop_runtime_number
          @stack << (a >= b)
        end

        def visit_lt(_op, _ctx)
          b = pop_runtime_number
          a = pop_runtime_number
          @stack << (a < b)
        end

        def visit_le(_op, _ctx)
          b = pop_runtime_number
          a = pop_runtime_number
          @stack << (a <= b)
        end

        def visit_and(_op, _ctx)
          b = @stack.pop
          a = @stack.pop
          result =
            if a.is_a?(Integer) && b.is_a?(Integer)
              a & b
            else
              truthy?(a) && truthy?(b)
            end
          @stack << result
        end

        def visit_or(_op, _ctx)
          b = @stack.pop
          a = @stack.pop
          result =
            if a.is_a?(Integer) && b.is_a?(Integer)
              a | b
            else
              truthy?(a) || truthy?(b)
            end
          @stack << result
        end

        def visit_xor(_op, _ctx)
          b = @stack.pop
          a = @stack.pop
          result =
            if a.is_a?(Integer) && b.is_a?(Integer)
              a ^ b
            else
              truthy?(a) != truthy?(b)
            end
          @stack << result
        end

        def visit_not(_op, _ctx)
          v = @stack.pop
          result = v.is_a?(Integer) ? ~v : !truthy?(v)
          @stack << result
        end

        def visit_bitshift(_op, _ctx)
          shift = pop_runtime_number.to_i
          v = pop_runtime_number.to_i
          @stack << (shift.negative? ? (v >> -shift) : (v << shift))
        end
        # truthy? and pop_runtime_number are provided by Common /
        # Arithmetic respectively.
      end
    end
  end
end
