# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Color operator handlers. Each updates the current
      # GraphicsContext; the next paint operator reads the new colors.
      module Color
        def visit_setgray(op, _ctx)
          color = Postscript::Color.gray(op.gray.to_f)
          @graphics.update(fill_color: color, stroke_color: color)
        end

        def visit_setrgbcolor(op, _ctx)
          color = Postscript::Color.rgb(op.red.to_f, op.green.to_f,
                                        op.blue.to_f)
          @graphics.update(fill_color: color, stroke_color: color)
        end

        def visit_setcmykcolor(op, _ctx)
          color = Postscript::Color.cmyk(op.cyan.to_f, op.magenta.to_f,
                                         op.yellow.to_f, op.key.to_f)
          @graphics.update(fill_color: color, stroke_color: color)
        end

        def visit_sethsbcolor(op, _ctx)
          color = hsb_to_color(op.hue.to_f, op.saturation.to_f,
                               op.brightness.to_f)
          @graphics.update(fill_color: color, stroke_color: color)
        end

        private

        # HSB to RGB. Standard algorithm.
        def hsb_to_color(h, s, v)
          h = h % 1.0
          i = (h * 6).floor
          f = (h * 6) - i
          p = v * (1 - s)
          q = v * (1 - (f * s))
          t = v * (1 - ((1 - f) * s))
          r, g, b =
            case (i % 6)
            when 0 then [v, t, p]
            when 1 then [q, v, p]
            when 2 then [p, v, t]
            when 3 then [p, q, v]
            when 4 then [t, p, v]
            else        [v, p, q]
            end
          Postscript::Color.rgb(r, g, b)
        end
      end
    end
  end
end
