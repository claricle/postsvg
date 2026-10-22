# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Coordinate transformation operator handlers. Each returns a
      # new CTM via Matrix composition and updates the GraphicsContext.
      module Transformations
        # A matrix this visitor produced (`matrix`, `currentmatrix`). The
        # runtime stack also holds values nothing popped (`def` operands,
        # unresolved names, path operands), so only these are trusted as a
        # matrix the parser could not see.
        class StackMatrix < Array; end

        def visit_translate(op, _ctx)
          new_ctm = @graphics.current.ctm.translate(op.tx.to_f, op.ty.to_f)
          @graphics.update(ctm: new_ctm)
        end

        def visit_scale(op, _ctx)
          consume_numeric_operands(op.sx, op.sy)
          new_ctm = @graphics.current.ctm.scale(op.sx.to_f, op.sy.to_f)
          @graphics.update(ctm: new_ctm)
        end

        def visit_rotate(op, _ctx)
          new_ctm = @graphics.current.ctm.rotate(op.angle.to_f)
          @graphics.update(ctm: new_ctm)
        end

        def visit_concat(op, _ctx)
          matrix = matrix_from_operand(matrix_operand(op))
          return unless matrix

          new_ctm = @graphics.current.ctm.multiply(matrix)
          @graphics.update(ctm: new_ctm)
        end

        def visit_matrix(_op, _ctx)
          @stack << StackMatrix[1, 0, 0, 1, 0, 0]
        end

        def visit_currentmatrix(_op, _ctx)
          @stack.pop if @stack.last.is_a?(StackMatrix)
          ctm = @graphics.current.ctm
          @stack << StackMatrix[ctm.a, ctm.b, ctm.c, ctm.d, ctm.e, ctm.f]
        end

        def visit_setmatrix(op, _ctx)
          matrix = matrix_from_operand(matrix_operand(op))
          return unless matrix

          @graphics.update(ctm: matrix)
        end

        def visit_transform(_op, _ctx)
          # Transform a point by the CTM: x y transform -> x' y'
          y = pop_number
          x = pop_number
          p = @graphics.current.ctm.apply_point(x, y)
          @stack << p[:x]
          @stack << p[:y]
        end

        def visit_dtransform(_op, _ctx)
          y = pop_number
          x = pop_number
          # Delta transform: ignore translation.
          ctm = @graphics.current.ctm
          dx = (x * ctm.a) + (y * ctm.c)
          dy = (x * ctm.b) + (y * ctm.d)
          @stack << dx
          @stack << dy
        end

        def visit_itransform(_op, _ctx)
          y = pop_number
          x = pop_number
          p = @graphics.current.ctm.invert.apply_point(x, y)
          @stack << p[:x]
          @stack << p[:y]
        end

        def visit_idtransform(_op, _ctx)
          y = pop_number
          x = pop_number
          inv = @graphics.current.ctm.invert
          dx = (x * inv.a) + (y * inv.c)
          dy = (x * inv.b) + (y * inv.d)
          @stack << dx
          @stack << dy
        end

        private

        # Parsed literal operands remain on the visitor stack. Consume only
        # an exact numeric suffix, leaving directly constructed operators alone.
        def consume_numeric_operands(*values)
          @stack.pop(values.length) if @stack.last(values.length) == values
        end

        # A literal matrix was also pushed by visit_array; consume that copy
        # so a later operator does not apply it again. A computed matrix is
        # taken from the stack only when this visitor produced it.
        def matrix_operand(op)
          unless op.matrix.is_a?(Model::Computed)
            @stack.pop if literal_on_stack?(op.matrix)
            return op.matrix
          end

          @stack.pop if @stack.last.is_a?(StackMatrix)
        end

        def literal_on_stack?(matrix)
          matrix.is_a?(Model::Literals::ArrayLiteral) && @stack.last.equal?(matrix.elements)
        end

        # Arrays on the runtime stack hold either plain numbers or parsed
        # Number literals. Anything other than six numbers is not a matrix.
        def matrix_from_operand(operand)
          case operand
          when Matrix then operand
          when Model::Literals::ArrayLiteral then matrix_from_operand(operand.elements)
          when Array
            numbers = operand.map { |element| matrix_number(element) }
            return nil unless numbers.length == 6 && numbers.all?

            Matrix.new(a: numbers[0], b: numbers[1], c: numbers[2],
                       d: numbers[3], e: numbers[4], f: numbers[5])
          end
        end

        def matrix_number(element)
          numeric_value(element) if element.is_a?(Numeric) || element.is_a?(Model::Literals::Number)
        end
      end
    end
  end
end
