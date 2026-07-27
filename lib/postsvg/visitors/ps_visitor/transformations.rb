# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Coordinate transformation operator handlers. Each returns a
      # new CTM via Matrix composition and updates the GraphicsContext.
      module Transformations
        def visit_translate(op, _ctx)
          new_ctm = @graphics.current.ctm.translate(op.tx.to_f, op.ty.to_f)
          @graphics.update(ctm: new_ctm)
        end

        def visit_scale(op, _ctx)
          new_ctm = @graphics.current.ctm.scale(op.sx.to_f, op.sy.to_f)
          @graphics.update(ctm: new_ctm)
        end

        def visit_rotate(op, _ctx)
          new_ctm = @graphics.current.ctm.rotate(op.angle.to_f)
          @graphics.update(ctm: new_ctm)
        end

        def visit_concat(op, _ctx)
          matrix = matrix_from_operand(op.matrix)
          return unless matrix

          new_ctm = @graphics.current.ctm.multiply(matrix)
          @graphics.update(ctm: new_ctm)
        end

        def visit_matrix(_op, _ctx)
          @stack << [1, 0, 0, 1, 0, 0]
        end

        def visit_currentmatrix(_op, _ctx)
          ctm = @graphics.current.ctm
          @stack << [ctm.a, ctm.b, ctm.c, ctm.d, ctm.e, ctm.f]
        end

        def visit_setmatrix(op, _ctx)
          matrix = matrix_from_operand(op.matrix)
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

        def matrix_from_operand(operand)
          case operand
          when Matrix then operand
          when Array
            return nil unless operand.length == 6

            Matrix.new(a: operand[0], b: operand[1], c: operand[2],
                       d: operand[3], e: operand[4], f: operand[5])
          end
        end
      end
    end
  end
end
