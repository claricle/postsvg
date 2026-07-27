# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Graphics state operator handlers: gsave/grestore and the line/
      # dash attribute setters.
      module GraphicsState
        def visit_gsave(_op, _ctx)
          @graphics.gsave
        end

        def visit_grestore(_op, _ctx)
          @graphics.grestore
        end

        def visit_grestoreall(_op, _ctx)
          @graphics.grestore while @graphics.depth > 1
        end

        def visit_setlinewidth(op, _ctx)
          @graphics.update(stroke_width: op.width.to_f)
        end

        def visit_setlinecap(op, _ctx)
          name = { 0 => :butt, 1 => :round, 2 => :square }.fetch(op.cap_code, :butt)
          @graphics.update(line_cap: name)
        end

        def visit_setlinejoin(op, _ctx)
          name = { 0 => :miter, 1 => :round, 2 => :bevel }.fetch(op.join_code, :miter)
          @graphics.update(line_join: name)
        end

        def visit_setmiterlimit(op, _ctx)
          @graphics.update(miter_limit: op.limit.to_f)
        end

        def visit_setdash(op, _ctx)
          pattern = op.pattern
          dash_str =
            case pattern
            when Array
              pattern.map { |v| FormatNumber.call(v.to_f) }.join(" ")
            when Numeric
              FormatNumber.call(pattern.to_f)
            else
              nil
            end
          @graphics.update(dash: dash_str)
        end
      end
    end
  end
end
