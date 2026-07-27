# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Arithmetic / math operator handlers. Each pops operands from
      # the RUNTIME stack (not the AST), computes the result, and
      # pushes it back. The AST operands are for parse-time stack
      # shape only; at runtime they may be +Computed+ sentinels
      # (from chained ops) and must be ignored.
      module Arithmetic
        def visit_add(_op, _ctx)
          b = pop_runtime_number
          a = pop_runtime_number
          @stack << (a + b)
        end

        def visit_sub(_op, _ctx)
          b = pop_runtime_number
          a = pop_runtime_number
          @stack << (a - b)
        end

        def visit_mul(_op, _ctx)
          b = pop_runtime_number
          a = pop_runtime_number
          @stack << (a * b)
        end

        def visit_div(_op, _ctx)
          divisor = pop_runtime_number
          a = pop_runtime_number
          raise RenderError, "division by zero" if divisor.zero?

          @stack << (a.to_f / divisor)
        end

        def visit_idiv(_op, _ctx)
          divisor = pop_runtime_number.to_i
          a = pop_runtime_number.to_i
          raise RenderError, "division by zero" if divisor.zero?

          @stack << (a / divisor)
        end

        def visit_mod(_op, _ctx)
          divisor = pop_runtime_number.to_i
          a = pop_runtime_number.to_i
          raise RenderError, "modulo by zero" if divisor.zero?

          @stack << (a % divisor)
        end

        def visit_neg(_op, _ctx)
          @stack << -pop_runtime_number
        end

        def visit_abs(_op, _ctx)
          @stack << pop_runtime_number.abs
        end

        def visit_ceiling(_op, _ctx)
          @stack << pop_runtime_number.to_f.ceil
        end

        def visit_floor(_op, _ctx)
          @stack << pop_runtime_number.to_f.floor
        end

        def visit_round(_op, _ctx)
          @stack << pop_runtime_number.to_f.round
        end

        def visit_truncate(_op, _ctx)
          @stack << pop_runtime_number.to_f.truncate
        end

        def visit_sqrt(_op, _ctx)
          operand = pop_runtime_number
          raise RenderError, "sqrt of negative" if operand.negative?

          @stack << Math.sqrt(operand.to_f)
        end

        def visit_atan(_op, _ctx)
          b = pop_runtime_number
          a = pop_runtime_number
          @stack << (Math.atan2(a.to_f, b.to_f) * (180.0 / Math::PI))
        end

        def visit_cos(_op, _ctx)
          @stack << Math.cos(pop_runtime_number.to_f * Math::PI / 180.0)
        end

        def visit_sin(_op, _ctx)
          @stack << Math.sin(pop_runtime_number.to_f * Math::PI / 180.0)
        end

        def visit_ln(_op, _ctx)
          @stack << Math.log(pop_runtime_number.to_f)
        end

        def visit_log(_op, _ctx)
          @stack << Math.log10(pop_runtime_number.to_f)
        end

        def visit_exp(_op, _ctx)
          b = pop_runtime_number
          a = pop_runtime_number
          @stack << (a.to_f**b.to_f)
        end

        private

        # Pop a value off the RUNTIME stack and resolve it to a
        # number. Names that resolve via the dict stack are followed.
        # Falls back to 0 for unknown values (mirroring parse-time
        # tolerance for +Computed+ sentinels).
        def pop_runtime_number
          numeric_value(@stack.pop)
        end
      end
    end
  end
end
