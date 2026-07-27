# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      # SVG `<path d="...">`. Walks the PathData command list and
      # emits equivalent PS path construction operators. Full SVG
      # path grammar support:
      #
      # - M/m moveto (relative repeats as l)
      # - L/l lineto
      # - H/h vertical line
      # - V/v horizontal line
      # - C/c cubic bezier
      # - S/s smooth cubic (reflects previous control point)
      # - Q/q quadratic bezier (converted to cubic)
      # - T/t smooth quadratic (converted to cubic)
      # - A/a arc (converted to PS arc via center-point parametrization)
      # - Z/z closepath
      class PathHandler
        extend Shared

        # Control-point reflection state for smooth curves. +nil+ when
        # the previous command wasn't a smooth-eligible curve.
        SmoothState = Struct.new(:control_x, :control_y, :smoothable,
                                 keyword_init: true)

        def self.call(element, context)
          context.emitter.emit(Model::Operators::GraphicsState::Gsave.new)
          emit_transform(element, context)
          context.emitter.emit(Model::Operators::Path::Newpath.new)

          state = PathState.new
          smooth = SmoothState.new(control_x: nil, control_y: nil,
                                   smoothable: false)
          element.commands.each do |cmd|
            dispatch_command(cmd, state, smooth, context)
          end
          emit_paint(element, context)
          context.emitter.emit(Model::Operators::GraphicsState::Grestore.new)
          expand_bbox(context, *state.bbox_points) if state.bbox_points.any?
        end

        def self.dispatch_command(cmd, state, smooth, context)
          case cmd.opcode
          when "M", "m"
            handle_moveto(cmd, state, smooth, context)
          when "L", "l"
            handle_lineto(cmd, state, context)
          when "H", "h"
            handle_hv(cmd, state, context, horizontal: cmd.opcode.upcase == "H")
          when "V", "v"
            handle_hv(cmd, state, context, horizontal: cmd.opcode.upcase == "V")
          when "C", "c"
            handle_cubic(cmd, state, smooth, context)
          when "S", "s"
            handle_smooth_cubic(cmd, state, smooth, context)
          when "Q", "q"
            handle_quadratic(cmd, state, smooth, context)
          when "T", "t"
            handle_smooth_quadratic(cmd, state, smooth, context)
          when "A", "a"
            handle_arc(cmd, state, context)
          when "Z", "z"
            context.emitter.emit(Model::Operators::Path::Closepath.new)
            state.close!
          end
        end

        # ---- per-command handlers ----

        def self.handle_moveto(cmd, state, smooth, context)
          x, y = cmd.args
          if cmd.opcode == "M"
            state.move_to(x, y)
            context.emitter.emit(Model::Operators::Path::Moveto.new(x: x, y: y))
          else
            state.move_to_rel(x, y)
            context.emitter.emit(Model::Operators::Path::Rmoveto.new(dx: x,
                                                                     dy: y))
          end
          smooth.smoothable = false
        end

        def self.handle_lineto(cmd, state, context)
          x, y = cmd.args
          if cmd.opcode == "L"
            state.line_to(x, y)
            context.emitter.emit(Model::Operators::Path::Lineto.new(x: x, y: y))
          else
            state.line_to_rel(x, y)
            context.emitter.emit(Model::Operators::Path::Rlineto.new(dx: x,
                                                                     dy: y))
          end
        end

        def self.handle_hv(cmd, state, context, horizontal:)
          v = cmd.args[0]
          if cmd.opcode.upcase == cmd.opcode # absolute
            if horizontal
              new_x = v
              state.line_to(new_x, state.current_y)
              context.emitter.emit(Model::Operators::Path::Lineto.new(x: new_x,
                                                                      y: state.current_y))
            else
              new_y = v
              state.line_to(state.current_x, new_y)
              context.emitter.emit(Model::Operators::Path::Lineto.new(
                                     x: state.current_x, y: new_y,
                                   ))
            end
          elsif horizontal
            state.line_to_rel(v, 0)
            context.emitter.emit(Model::Operators::Path::Rlineto.new(dx: v,
                                                                     dy: 0))
          else
            state.line_to_rel(0, v)
            context.emitter.emit(Model::Operators::Path::Rlineto.new(dx: 0,
                                                                     dy: v))
          end
        end

        def self.handle_cubic(cmd, state, smooth, context)
          args = cmd.args
          x1, y1, x2, y2, x3, y3 = adapt_curve_args(args, cmd.opcode, state)
          state.curve_to(x3, y3)
          context.emitter.emit(Model::Operators::Path::Curveto.new(
                                 x1: x1, y1: y1, x2: x2, y2: y2, x3: x3, y3: y3,
                               ))
          smooth.control_x = x2
          smooth.control_y = y2
          smooth.smoothable = true
        end

        def self.handle_smooth_cubic(cmd, state, smooth, context)
          x2, y2, x3, y3 = cmd.args
          if cmd.opcode == "S"
            x1, y1 = reflect_control(smooth, state)
            state.curve_to(x3, y3)
            context.emitter.emit(Model::Operators::Path::Curveto.new(
                                   x1: x1, y1: y1, x2: x2, y2: y2, x3: x3, y3: y3,
                                 ))
          else
            dx1, dy1 = reflect_control_rel(smooth, state)
            state.curve_to_rel(dx2: x2, dy2: y2, dx3: x3, dy3: y3, dx1: dx1,
                               dy1: dy1)
            context.emitter.emit(Model::Operators::Path::Rcurveto.new(
                                   dx1: dx1, dy1: dy1, dx2: x2, dy2: y2, dx3: x3, dy3: y3,
                                 ))
            x2 = state.current_x - x2
            y2 = state.current_y - y2
          end
          smooth.control_x = state.current_x + (x2 - state.current_x)
          smooth.control_y = state.current_y + (y2 - state.current_y)
          smooth.smoothable = true
        end

        def self.handle_quadratic(cmd, state, smooth, context)
          args = cmd.args
          qx, qy, x3, y3 = adapt_quadratic_args(args, cmd.opcode, state)
          # Convert quadratic to cubic: c1 = p0 + 2/3*(q-p0),
          # c2 = p3 + 2/3*(q-p3).
          p0x = state.current_x
          p0y = state.current_y
          c1x = p0x + ((2.0 / 3.0) * (qx - p0x))
          c1y = p0y + ((2.0 / 3.0) * (qy - p0y))
          c2x = x3 + ((2.0 / 3.0) * (qx - x3))
          c2y = y3 + ((2.0 / 3.0) * (qy - y3))
          state.curve_to(x3, y3)
          context.emitter.emit(Model::Operators::Path::Curveto.new(
                                 x1: c1x, y1: c1y, x2: c2x, y2: c2y, x3: x3, y3: y3,
                               ))
          smooth.control_x = qx
          smooth.control_y = qy
          smooth.smoothable = true
        end

        def self.handle_smooth_quadratic(cmd, state, smooth, context)
          x3, y3 = cmd.args
          qx, qy =
            if smooth.smoothable
              [reflect_x(smooth.control_x, state),
               reflect_y(smooth.control_y, state)]
            else
              [state.current_x, state.current_y]
            end
          p0x = state.current_x
          p0y = state.current_y
          c1x = p0x + ((2.0 / 3.0) * (qx - p0x))
          c1y = p0y + ((2.0 / 3.0) * (qy - p0y))
          c2x = x3 + ((2.0 / 3.0) * (qx - x3))
          c2y = y3 + ((2.0 / 3.0) * (qy - y3))
          if cmd.opcode == "T"
            state.curve_to(x3, y3)
          else
            state.curve_to_rel(x3 - p0x, y3 - p0y) # treat as rel target
            # Re-anchor to absolute target for emission below.
            state.current_x = p0x + x3
            state.current_y = p0y + y3
          end
          context.emitter.emit(Model::Operators::Path::Curveto.new(
                                 x1: c1x, y1: c1y, x2: c2x, y2: c2y, x3: state.current_x, y3: state.current_y,
                               ))
          smooth.control_x = qx
          smooth.control_y = qy
          smooth.smoothable = true
        end

        # Convert SVG elliptical arc to PS arc(s). SVG arc parametrizes
        # by endpoint + flags; PS arc is center-based. Use the
        # W3C-endorsed endpoint-to-center conversion.
        def self.handle_arc(cmd, state, context)
          rx, ry, x_axis_rotation, large_arc_flag, sweep_flag, x, y = cmd.args
          cx, cy, normalized_rx, normalized_ry, psi, theta1, theta2 =
            Postsvg::Translation::ArcConverter.endpoint_to_center(
              x1: state.current_x, y1: state.current_y,
              rx: rx, ry: ry, x_axis_rotation: x_axis_rotation,
              large_arc: large_arc_flag != 0, sweep: sweep_flag != 0,
              x2: x, y2: y
            )
          # Emit arc with center, radius, angle range. For elliptical
          # arcs (rx != ry or non-zero rotation), emit scale/rotate
          # transforms around the arc.
          if x_axis_rotation.abs > 1e-6 || (rx - ry).abs > 1e-6
            context.emitter.emit(Model::Operators::GraphicsState::Gsave.new)
            context.emitter.emit(Model::Operators::Transformations::Concat.new(matrix: [
                                                                                 Math.cos(psi), Math.sin(psi), -Math.sin(psi), Math.cos(psi), cx, cy
                                                                               ]))
            context.emitter.emit(Model::Operators::Transformations::Scale.new(
                                   sx: normalized_rx, sy: normalized_ry,
                                 ))
            context.emitter.emit(Model::Operators::Path::Arc.new(
                                   x: 0, y: 0, radius: 1.0, angle1: theta1, angle2: theta2,
                                 ))
            context.emitter.emit(Model::Operators::GraphicsState::Grestore.new)
          else
            context.emitter.emit(Model::Operators::Path::Arc.new(
                                   x: cx, y: cy, radius: normalized_rx, angle1: theta1, angle2: theta2,
                                 ))
          end
          state.move_to(x, y)
        end

        # ---- helpers ----

        def self.adapt_curve_args(args, opcode, state)
          return args if opcode.upcase == opcode

          # Relative: dxN/dyN become xN = current + dxN
          x1 = state.current_x + args[0]
          y1 = state.current_y + args[1]
          x2 = state.current_x + args[2]
          y2 = state.current_y + args[3]
          x3 = state.current_x + args[4]
          y3 = state.current_y + args[5]
          [x1, y1, x2, y2, x3, y3]
        end

        def self.adapt_quadratic_args(args, opcode, state)
          return args if opcode.upcase == opcode

          qx = state.current_x + args[0]
          qy = state.current_y + args[1]
          x3 = state.current_x + args[2]
          y3 = state.current_y + args[3]
          [qx, qy, x3, y3]
        end

        def self.reflect_control(smooth, state)
          return [state.current_x, state.current_y] unless smooth.smoothable

          [reflect_x(smooth.control_x, state),
           reflect_y(smooth.control_y, state)]
        end

        def self.reflect_control_rel(smooth, state)
          abs_x, abs_y = reflect_control(smooth, state)
          [abs_x - state.current_x, abs_y - state.current_y]
        end

        def self.reflect_x(control_x, state)
          (2 * state.current_x) - control_x
        end

        def self.reflect_y(control_y, state)
          (2 * state.current_y) - control_y
        end

        # Mutable path-tracking state shared across command handlers.
        # Tracks current pen position + start-of-subpath (for Z) +
        # accumulated bbox vertices.
        class PathState
          attr_reader :current_x, :current_y, :start_x, :start_y, :bbox_points

          def initialize
            @current_x = 0.0
            @current_y = 0.0
            @start_x = nil
            @start_y = nil
            @bbox_points = []
          end

          def move_to(x, y)
            @current_x = x.to_f
            @current_y = y.to_f
            @start_x ||= @current_x
            @start_y ||= @current_y
            track(x, y)
          end

          def move_to_rel(dx, dy)
            @current_x += dx.to_f
            @current_y += dy.to_f
            @start_x ||= @current_x
            @start_y ||= @current_y
            track(@current_x, @current_y)
          end

          def line_to(x, y)
            @current_x = x.to_f
            @current_y = y.to_f
            track(x, y)
          end

          def line_to_rel(dx, dy)
            @current_x += dx.to_f
            @current_y += dy.to_f
            track(@current_x, @current_y)
          end

          def curve_to(x3, y3)
            @current_x = x3.to_f
            @current_y = y3.to_f
            track(x3, y3)
          end

          def curve_to_rel(dx1:, dy1:, dx2:, dy2:, dx3:, dy3:)
            # We don't track c1/c2 — only the endpoint enters bbox.
            @current_x += dx3.to_f
            @current_y += dy3.to_f
            track(@current_x, @current_y)
          end

          def close!
            if @start_x
              @current_x = @start_x
              @current_y = @start_y
            end
            @start_x = nil
            @start_y = nil
          end

          def current_x
            @current_x
          end

          def current_y
            @current_y
          end

          private

          def track(x, y)
            @bbox_points << x
            @bbox_points << y
          end
        end
        private_constant :PathState
      end
    end
  end
end
