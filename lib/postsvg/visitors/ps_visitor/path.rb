# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Path construction operator handlers. Each appends a command to
      # +@path+ (PathState). CTM-aware: when the current CTM is not
      # identity, the renderer wraps painted paths in a <g transform=>.
      # Temporary arc transforms are mapped back into the path's user space
      # so restoring the CTM preserves the geometry already constructed.
      # Other mid-path CTM changes retain the existing paint-time behavior.
      module Path
        def visit_newpath(_op, _ctx)
          @path.reset
        end

        def visit_moveto(op, _ctx)
          @path.matrix ||= @graphics.current.ctm
          @path.move_to(op.x, op.y)
          @graphics.update(last_text_position: { x: op.x, y: op.y })
        end

        def visit_rmoveto(op, _ctx)
          @path.matrix ||= @graphics.current.ctm
          @path.move_to_rel(op.dx, op.dy)
          pos = @graphics.current.last_text_position
          base_x = pos ? pos[:x] : 0
          base_y = pos ? pos[:y] : 0
          @graphics.update(last_text_position: { x: base_x + op.dx,
                                                 y: base_y + op.dy })
        end

        def visit_lineto(op, _ctx)
          @path.line_to(op.x, op.y)
        end

        def visit_rlineto(op, _ctx)
          @path.line_to_rel(op.dx, op.dy)
        end

        def visit_curveto(op, _ctx)
          @path.curve_to(op.x1, op.y1, op.x2, op.y2, op.x3, op.y3)
        end

        def visit_rcurveto(op, _ctx)
          @path.curve_to_rel(op.dx1, op.dy1, op.dx2, op.dy2, op.dx3, op.dy3)
        end

        def visit_arc(op, _ctx)
          append_arc(op.x, op.y, op.radius, op.angle1, op.angle2, sweep: true)
        end

        def visit_arcn(op, _ctx)
          append_arc(op.x, op.y, op.radius, op.angle1, op.angle2, sweep: false)
        end

        def visit_closepath(_op, _ctx)
          @path.close
        end

        def visit_currentpoint(_op, _ctx)
          @stack << @path.current_x
          @stack << @path.current_y
        end

        private

        # Convert a PS arc into one or two SVG arc commands. PS arcs
        # are parametrised by center, radius, angle range. SVG arcs
        # are parametrised by endpoint, radii, large-arc/sweep flags.
        def append_arc(cx, cy, radius, angle1, angle2, sweep:)
          consume_numeric_operands(cx, cy, radius, angle1, angle2)
          r = radius.abs
          return if r.zero?

          @path.matrix ||= @graphics.current.ctm
          matrix = @path.matrix.invert.multiply(@graphics.current.ctm)
          start_x, start_y = arc_point(matrix, cx, cy, r, angle1)
          end_x, end_y = arc_point(matrix, cx, cy, r, angle2)
          @path.move_to(start_x, start_y) if @path.empty?

          delta = sweep ? (angle2 - angle1) % 360 : (angle1 - angle2) % 360
          rx, ry, rotation = arc_radii(matrix, r)
          reflected = ((matrix.a * matrix.d) - (matrix.b * matrix.c)).negative?
          svg_sweep = sweep != reflected
          if delta.abs < 1e-6
            # Full circles need two arcs; retain the corpus's large-arc spelling.
            mid_x, mid_y = arc_point(matrix, cx, cy, r, angle1 + 180)
            @path.arc_to(rx, ry, rotation, true, svg_sweep, mid_x, mid_y)
            @path.arc_to(rx, ry, rotation, true, svg_sweep, start_x, start_y)
            @path.close
          else
            @path.arc_to(rx, ry, rotation, delta > 180, svg_sweep, end_x, end_y)
          end
        end

        def arc_point(matrix, cx, cy, radius, angle)
          radians = angle * Math::PI / 180.0
          matrix.apply_point(cx + (radius * Math.cos(radians)),
                             cy + (radius * Math.sin(radians))).values_at(:x, :y)
        end

        # Singular values give the ellipse radii even when its frame is rotated
        # or sheared. The principal eigenvector gives its SVG axis rotation.
        def arc_radii(matrix, radius)
          xx = (matrix.a**2) + (matrix.c**2)
          xy = (matrix.a * matrix.b) + (matrix.c * matrix.d)
          yy = (matrix.b**2) + (matrix.d**2)
          root = Math.hypot(xx - yy, 2 * xy)
          rx = radius * Math.sqrt([(xx + yy + root) / 2, 0].max)
          ry = radius * Math.sqrt([(xx + yy - root) / 2, 0].max)
          rotation = root < 1e-12 ? 0.0 : Math.atan2(2 * xy, xx - yy) * 90 / Math::PI
          [rx, ry, rotation]
        end
      end
    end
  end
end
