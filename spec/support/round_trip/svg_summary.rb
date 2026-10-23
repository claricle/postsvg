# frozen_string_literal: true

module RoundTrip
  # Reduces SVG syntax to painted geometry in document coordinates. This keeps
  # the contract concerned with what is drawn rather than which SVG primitive
  # or relative path spelling was used to draw it.
  class SvgSummary
    IDENTITY = [1.0, 0.0, 0.0, 1.0, 0.0, 0.0].freeze
    ROUND_DIGITS = 2

    def self.call(svg)
      new(Postsvg::Svg::Parser.call(svg)).call
    end

    def initialize(document)
      @document = document
      @items = []
    end

    def call
      visit(@document.root_element, IDENTITY)
      coalesce_paint(@items)
    end

    private

    def visit(element, parent_matrix)
      matrix = multiply(parent_matrix, matrix_for(element))
      if container?(element)
        element.children.each { |child| visit(child, matrix) }
      else
        append_item(element, matrix)
      end
    end

    def container?(element)
      element.is_a?(Postsvg::Svg::Elements::Svg) ||
        element.is_a?(Postsvg::Svg::Elements::Group) ||
        element.is_a?(Postsvg::Svg::Elements::Defs) ||
        element.is_a?(Postsvg::Svg::OpenElement)
    end

    def append_item(element, matrix)
      item = item_for(element, matrix)
      @items << item if item
    end

    def item_for(element, matrix)
      geometry = geometry_for(element, matrix)
      return unless geometry

      item = { geometry: geometry }
      if element.is_a?(Postsvg::Svg::Elements::Text)
        item.merge!(text: element.content, font_family: element.font_family,
                    font_size: number(element.font_size))
      end
      item.merge!(paint_for(element))
    end

    def geometry_for(element, matrix)
      case element
      when Postsvg::Svg::Elements::Rect
        rect_geometry(element, matrix)
      when Postsvg::Svg::Elements::Circle
        ellipse_geometry(element.cx, element.cy, element.r, element.r, matrix)
      when Postsvg::Svg::Elements::Ellipse
        ellipse_geometry(element.cx, element.cy, element.rx, element.ry, matrix)
      when Postsvg::Svg::Elements::Line
        commands_geometry([command("M", element.x1, element.y1),
                           command("L", element.x2, element.y2)], matrix)
      when Postsvg::Svg::Elements::Polyline
        points_geometry(element.points, matrix,
                        close: element.is_a?(Postsvg::Svg::Elements::Polygon))
      when Postsvg::Svg::Elements::Path
        commands_geometry(element.commands, matrix)
      when Postsvg::Svg::Elements::Text
        { type: :text, at: point(matrix, element.x, element.y) }
      end
    end

    def rect_geometry(rect, matrix)
      commands = [command("M", rect.x, rect.y),
                  command("L", rect.x + rect.width, rect.y),
                  command("L", rect.x + rect.width, rect.y + rect.height),
                  command("L", rect.x, rect.y + rect.height), command("Z")]
      commands_geometry(commands, matrix)
    end

    def points_geometry(points, matrix, close:)
      commands = points.each_slice(2).with_index.map do |(x, y), index|
        command(index.zero? ? "M" : "L", x, y)
      end
      commands << command("Z") if close
      commands_geometry(commands, matrix)
    end

    def ellipse_geometry(cx, cy, rx, ry, matrix)
      commands = [command("M", cx + rx, cy),
                  command("A", rx, ry, 0, 1, 1, cx - rx, cy),
                  command("A", rx, ry, 0, 1, 1, cx + rx, cy), command("Z")]
      commands_geometry(commands, matrix)
    end

    def command(opcode, *args)
      Postsvg::Svg::PathData::Command.new(opcode: opcode, args: args)
    end

    def commands_geometry(commands, matrix)
      state = { current: [0.0, 0.0], start: [0.0, 0.0], cubic_control: nil,
                quadratic_control: nil }
      normalized = commands.filter_map { |cmd| normalize_command(cmd, state, matrix) }
      { type: :path, commands: normalized }
    end

    def normalize_command(cmd, state, matrix)
      args = cmd.args
      relative = cmd.relative?
      case cmd.opcode.upcase
      when "M", "L", "T"
        normalize_point_command(cmd.opcode.upcase, args, relative, state, matrix)
      when "H", "V"
        normalize_axis_command(cmd.opcode.upcase, args.first, relative, state, matrix)
      when "C"
        normalize_cubic(args, relative, state, matrix)
      when "S"
        normalize_smooth_cubic(args, relative, state, matrix)
      when "Q"
        normalize_quadratic(args, relative, state, matrix)
      when "A"
        normalize_arc(args, relative, state, matrix)
      when "Z"
        state[:current] = state[:start]
        reset_controls(state)
        ["Z"]
      end
    end

    def normalize_point_command(opcode, args, relative, state, matrix)
      target = absolute_point(args, relative, state[:current])
      if opcode == "T"
        return normalize_smooth_quadratic(target, false, state, matrix)
      end

      state[:current] = target
      state[:start] = target if opcode == "M"
      reset_controls(state)
      [opcode, *point(matrix, *target)]
    end

    def normalize_axis_command(opcode, value, relative, state, matrix)
      x, y = state[:current]
      if opcode == "H"
        x = relative ? x + value : value
      else
        y = relative ? y + value : value
      end
      state[:current] = [x, y]
      reset_controls(state)
      ["L", *point(matrix, x, y)]
    end

    def normalize_cubic(args, relative, state, matrix)
      control1 = absolute_point(args[0, 2], relative, state[:current])
      control2 = absolute_point(args[2, 2], relative, state[:current])
      target = absolute_point(args[4, 2], relative, state[:current])
      state[:current] = target
      state[:cubic_control] = control2
      state[:quadratic_control] = nil
      ["C", *point(matrix, *control1), *point(matrix, *control2),
       *point(matrix, *target)]
    end

    def normalize_smooth_cubic(args, relative, state, matrix)
      control1 = reflect(state[:cubic_control], state[:current])
      normalize_cubic([*relative_delta(control1, relative, state[:current]), *args],
                      relative, state, matrix)
    end

    def normalize_quadratic(args, relative, state, matrix)
      start = state[:current]
      control = absolute_point(args[0, 2], relative, start)
      target = absolute_point(args[2, 2], relative, start)
      control1 = interpolate(start, control, 2.0 / 3)
      control2 = interpolate(target, control, 2.0 / 3)
      state[:current] = target
      state[:quadratic_control] = control
      state[:cubic_control] = nil
      ["C", *point(matrix, *control1), *point(matrix, *control2),
       *point(matrix, *target)]
    end

    def normalize_smooth_quadratic(args, relative, state, matrix)
      control = reflect(state[:quadratic_control], state[:current])
      values = [*relative_delta(control, relative, state[:current]), *args]
      normalize_quadratic(values, relative, state, matrix)
    end

    def normalize_arc(args, relative, state, matrix)
      rx, ry, rotation, large_arc, sweep, x, y = args
      target = absolute_point([x, y], relative, state[:current])
      transformed_rx, transformed_ry, transformed_rotation =
        transformed_ellipse(rx, ry, rotation, matrix)
      sweep = 1 - sweep.to_i if determinant(matrix).negative?
      state[:current] = target
      reset_controls(state)
      ["A", transformed_rx, transformed_ry, transformed_rotation,
       large_arc.to_i, sweep.to_i, *point(matrix, *target)]
    end

    def transformed_ellipse(rx, ry, rotation, matrix)
      angle = rotation * Math::PI / 180.0
      cos = Math.cos(angle)
      sin = Math.sin(angle)
      a, b, c, d = matrix.first(4)
      ux = (a * rx * cos) + (c * rx * sin)
      uy = (b * rx * cos) + (d * rx * sin)
      vx = (-a * ry * sin) + (c * ry * cos)
      vy = (-b * ry * sin) + (d * ry * cos)
      xx = (ux * ux) + (vx * vx)
      xy = (ux * uy) + (vx * vy)
      yy = (uy * uy) + (vy * vy)
      root = Math.sqrt(((xx - yy)**2) + (4 * xy * xy))
      radii = [Math.sqrt((xx + yy + root) / 2.0),
               Math.sqrt((xx + yy - root) / 2.0)]
      angle_out = root < 0.000001 ? 0.0 : Math.atan2(2 * xy, xx - yy) * 90.0 / Math::PI
      [*radii.map { |radius| number(radius) }, number(angle_out)]
    end

    def paint_for(element)
      fill = paint(element.fill)
      stroke = paint(element.stroke_paint)
      result = { fill: fill, stroke: stroke }
      return result unless stroke

      result.merge(stroke_width: number(element.stroke.width),
                   stroke_linecap: element.stroke.linecap,
                   stroke_linejoin: element.stroke.linejoin)
    end

    def paint(value)
      return unless value
      return value.value.to_svg if value.color?

      "url(##{value.value})" if value.reference?
    end

    def coalesce_paint(items)
      items.each_with_object([]) do |item, result|
        previous = result.last
        if mergeable_paint?(previous, item)
          previous.merge!(item.reject { |key, value| key == :geometry || value.nil? })
        else
          result << item
        end
      end
    end

    def mergeable_paint?(left, right)
      return false unless left && left[:geometry] == right[:geometry]

      fill_then_stroke?(left, right) || fill_then_stroke?(right, left)
    end

    def fill_then_stroke?(fill_item, stroke_item)
      fill_item[:fill] && !fill_item[:stroke] &&
        !stroke_item[:fill] && stroke_item[:stroke]
    end

    def matrix_for(element)
      element.transform&.matrices&.reduce(IDENTITY) do |result, matrix|
        multiply(result, [matrix.a, matrix.b, matrix.c, matrix.d, matrix.e, matrix.f])
      end || IDENTITY
    end

    def multiply(left, right)
      a1, b1, c1, d1, e1, f1 = left
      a2, b2, c2, d2, e2, f2 = right
      [(a1 * a2) + (c1 * b2), (b1 * a2) + (d1 * b2),
       (a1 * c2) + (c1 * d2), (b1 * c2) + (d1 * d2),
       (a1 * e2) + (c1 * f2) + e1, (b1 * e2) + (d1 * f2) + f1]
    end

    def point(matrix, x, y)
      a, b, c, d, e, f = matrix
      [number((a * x) + (c * y) + e), number((b * x) + (d * y) + f)]
    end

    def determinant(matrix)
      (matrix[0] * matrix[3]) - (matrix[1] * matrix[2])
    end

    def absolute_point(pair, relative, origin)
      return pair unless relative

      [origin[0] + pair[0], origin[1] + pair[1]]
    end

    def relative_delta(point_value, relative, origin)
      return point_value unless relative

      [point_value[0] - origin[0], point_value[1] - origin[1]]
    end

    def reflect(control, current)
      return current unless control

      [(2 * current[0]) - control[0], (2 * current[1]) - control[1]]
    end

    def interpolate(from, to, amount)
      [from[0] + ((to[0] - from[0]) * amount),
       from[1] + ((to[1] - from[1]) * amount)]
    end

    def reset_controls(state)
      state[:cubic_control] = nil
      state[:quadratic_control] = nil
    end

    def number(value)
      rounded = value.to_f.round(ROUND_DIGITS)
      rounded.zero? ? 0.0 : rounded
    end
  end
end
