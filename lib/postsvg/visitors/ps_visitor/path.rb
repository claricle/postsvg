# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Path construction operator handlers. Each appends a command to
      # +@path+ (PathState). CTM-aware: when the current CTM is not
      # identity, the renderer will wrap emitted paths in a
      # <g transform=>. Points are stored in user-space coordinates;
      # the visitor delegates to the SvgBuilder for transform emission.
      module Path
        def visit_newpath(_op, _ctx)
          @path.reset
        end

        def visit_moveto(op, _ctx)
          @path.move_to(op.x, op.y)
          @graphics.update(last_text_position: { x: op.x, y: op.y })
        end

        def visit_rmoveto(op, _ctx)
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
          r = radius.abs
          return if r.zero?

          start_rad = angle1 * Math::PI / 180.0
          start_x = cx + (r * Math.cos(start_rad))
          start_y = cy + (r * Math.sin(start_rad))
          end_rad = angle2 * Math::PI / 180.0
          end_x = cx + (r * Math.cos(end_rad))
          end_y = cy + (r * Math.sin(end_rad))

          # If the current path is empty, the arc implicitly starts
          # with a moveto to its starting point.
          if (@path.empty? || last_command_starts_with?("M")) && @path.empty?
            @path.move_to(start_x, start_y)
          end

          delta = (angle2 - angle1) % 360
          delta += 360 if delta.negative?
          large_arc = delta > 180

          # SVG sweep flag is 1 when the arc is drawn clockwise.
          svg_sweep = if sweep
                        delta.positive? ? 1 : 0
                      else
                        0
                      end
          if delta.abs < 1e-6
            # Full circle: emit two arcs.
            mid_angle = angle1 + 180
            mid_rad = mid_angle * Math::PI / 180.0
            mid_x = cx + (r * Math.cos(mid_rad))
            mid_y = cy + (r * Math.sin(mid_rad))
            @path.arc_to(r, r, 0, 0, svg_sweep, mid_x, mid_y)
            @path.arc_to(r, r, 0, 0, svg_sweep, start_x, start_y)
            @path.close
          else
            @path.arc_to(r, r, 0, large_arc ? 1 : 0, svg_sweep, end_x, end_y)
          end
        end

        def last_command_starts_with?(prefix)
          return false if @path.commands.empty?

          @path.commands.last.start_with?(prefix)
        end
      end
    end
  end
end
