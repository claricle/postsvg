# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Control flow operator handlers. Each pops operands from the
      # RUNTIME stack (not the AST), so chained execution behaves
      # correctly. Bodies are +Procedure+ values that +descend_into_procedure+
      # walks in the current visitor context.
      module ControlFlow
        LOOP_LIMIT = 10_000

        def visit_if(_op, _ctx)
          body = @stack.pop
          condition = @stack.pop
          return unless truthy?(condition)

          descend_into_procedure(body)
        end

        def visit_ifelse(_op, _ctx)
          else_body = @stack.pop
          if_body = @stack.pop
          condition = @stack.pop
          if truthy?(condition)
            descend_into_procedure(if_body)
          else
            descend_into_procedure(else_body)
          end
        end

        def visit_repeat(_op, _ctx)
          body = @stack.pop
          count = pop_runtime_number.to_i.clamp(0, LOOP_LIMIT)
          count.times { descend_into_procedure(body) }
        end

        def visit_loop(_op, _ctx)
          body = @stack.pop
          LOOP_LIMIT.times do
            descend_into_procedure(body)
          rescue Postsvg::ExitSignal
            break
          end
        end

        def visit_for(_op, _ctx)
          body = @stack.pop
          limit = pop_runtime_number.to_f
          increment = pop_runtime_number.to_f
          initial = pop_runtime_number.to_f
          iterations = 0
          if increment.positive?
            value = initial
            while value <= limit
              @stack << value
              descend_into_procedure(body)
              value += increment
              iterations += 1
              break if iterations > LOOP_LIMIT
            end
          elsif increment.negative?
            value = initial
            while value >= limit
              @stack << value
              descend_into_procedure(body)
              value += increment
              iterations += 1
              break if iterations > LOOP_LIMIT
            end
          else
            raise RenderError, "for: zero increment"
          end
        end

        def visit_exit(_op, _ctx)
          raise Postsvg::ExitSignal
        end

        def visit_quit(_op, _ctx)
          raise Postsvg::QuitSignal
        end

        def visit_exec(_op, _ctx)
          operand = @stack.pop
          case operand
          when Model::Literals::Procedure
            descend_into_procedure(operand)
          else
            @stack << operand
          end
        end

        def visit_stopped(_op, _ctx)
          body = @stack.pop
          descend_into_procedure(body)
          @stack << false
        end

        def descend_into_procedure(procedure)
          return unless procedure.is_a?(Model::Literals::Procedure)

          procedure.body.each { |node| node.accept(self, nil) }
        end
        # truthy? and pop_runtime_number are provided by Common /
        # Arithmetic respectively.
      end
    end
  end
end
