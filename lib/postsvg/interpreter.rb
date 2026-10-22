# frozen_string_literal: true

require_relative "matrix"
require_relative "path_builder"
require_relative "colors"
require_relative "tokenizer"

module Postsvg
  # Stack-based PostScript interpreter
  class Interpreter
    FILL_ONLY = { stroke: false, fill: true }.freeze
    STROKE_ONLY = { stroke: true, fill: false }.freeze
    FILL_AND_STROKE = { stroke: true, fill: true }.freeze

    DEFAULT_IMAGE = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy" \
                    "53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI1MTIiIGhlaWdodD0iNTEyIj4KICA" \
                    "8dGV4dCB4PSIyNCIgeT0iMTk4IiBmaWxsPSJ3aGl0ZSIgZm9udC1zaXplPSIxM" \
                    "jgiPkltYWdlbTwvdGV4dD4KICA8dGV4dCB4PSIyNCIgeT0iMjk4IiBmaWxsPSJ" \
                    "3aGl0ZSIgZm9udC1zaXplPSIxMjgiPk5vdDwvdGV4dD4KICA8dGV4dCB4PSIyN" \
                    "CIgeT0iMzk4IiBmaWxsPSJ3aGl0ZSIgZm9udC1zaXplPSIxMjgiPkZvdW5kPC9" \
                    "0ZXh0Pgo8L3N2Zz4K"

    PATH_TERMINATORS = %w[stroke fill show moveto newpath].freeze
    PATH_CONTINUATORS = %w[lineto curveto rlineto rcurveto].freeze
    STATE_MODIFIERS = %w[
      setrgbcolor setgray setcmykcolor setlinewidth setlinecap
      setlinejoin setdash translate scale rotate
    ].freeze

    def initialize
      @stack = []
      @g_stack = []
      @g_state = default_graphics_state
      @path = PathBuilder.new
      @current_x = 0
      @current_y = 0
      @id_counter = 0
      @svg_out = { defs: [], element_shapes: [], element_texts: [] }
      @global_dict = {}
      @dict_stack = [@global_dict]

      # Initialize path with correct transform mode
      update_path_transform_mode
    end

    def interpret(tokens, _bounding_box = nil)
      i = 0
      while i < tokens.length
        token = tokens[i]

        case token.type
        when "number"
          @stack << token.value.to_f
        when "string", "hexstring", "name"
          @stack << token.value
        when "brace"
          if token.value == "{"
            proc_result = parse_procedure(tokens, i + 1)
            @stack << { type: "procedure", body: proc_result[:procedure] }
            i = proc_result[:next_index] - 1
          end
        when "bracket"
          if token.value == "["
            array_result = parse_array(tokens, i + 1)
            @stack << array_result[:array]
            i = array_result[:next_index] - 1
          end
        when "dict"
          if token.value == "<<"
            dict_result = parse_dict(tokens, i + 1)
            @stack << dict_result[:dict]
            i = dict_result[:next_index] - 1
          end
        when "operator"
          execute_operator(token.value, tokens, i)
        end

        i += 1
      end

      # Flush remaining path
      flush_path(STROKE_ONLY) if @path.length.positive?

      @svg_out
    end

    private

    def default_graphics_state
      {
        ctm: Matrix.new,
        fill: "black",
        stroke: nil,
        stroke_width: 1,
        line_cap: "butt",
        line_join: "miter",
        font: "Arial, sans-serif",
        font_size: 12,
        clip_stack: [],
        dash: nil,
        last_text_pos: nil,
        pattern: nil,
        pattern_dict: nil,
      }
    end

    def clone_graphic_state(state)
      {
        ctm: Matrix.new(
          a: state[:ctm].a, b: state[:ctm].b, c: state[:ctm].c,
          d: state[:ctm].d, e: state[:ctm].e, f: state[:ctm].f
        ),
        fill: state[:fill],
        stroke: state[:stroke],
        stroke_width: state[:stroke_width],
        line_cap: state[:line_cap],
        line_join: state[:line_join],
        font: state[:font],
        font_size: state[:font_size],
        clip_stack: state[:clip_stack].dup,
        dash: state[:dash],
        last_text_pos: state[:last_text_pos]&.dup,
        pattern: state[:pattern],
        pattern_dict: state[:pattern_dict]&.dup,
      }
    end

    def update_path_transform_mode
      need_group = !@g_state[:ctm].identity? || !@g_state[:clip_stack].empty?
      @path.set_transform_mode(need_group, need_group ? nil : @g_state[:ctm])
    end

    def parse_procedure(tokens, start_index)
      procedure = []
      depth = 1
      index = start_index

      while index < tokens.length && depth.positive?
        token = tokens[index]
        if token.type == "brace" && token.value == "{"
          depth += 1
        elsif token.type == "brace" && token.value == "}"
          depth -= 1
          return { procedure: procedure, next_index: index + 1 } if depth.zero?
        end
        procedure << token if depth.positive?
        index += 1
      end

      { procedure: procedure, next_index: index }
    end

    def parse_array(tokens, start_index)
      array = []
      index = start_index

      while index < tokens.length
        token = tokens[index]
        if token.type == "bracket" && token.value == "]"
          return { array: array,
                   next_index: index + 1 }
        end

        if token.type == "number"
          array << token.value.to_f
        elsif %w[string name].include?(token.type)
          array << token.value
        end
        index += 1
      end

      { array: array, next_index: index }
    end

    def parse_dict(tokens, start_index)
      dict = {}
      index = start_index
      current_key = nil

      while index < tokens.length
        token = tokens[index]

        if token.type == "dict" && token.value == ">>"
          return { dict: dict,
                   next_index: index + 1 }
        end

        if token.type == "name"
          current_key = token.value
        elsif current_key
          if token.type == "number"
            dict[current_key] = token.value.to_f
            current_key = nil
          elsif %w[string hexstring].include?(token.type)
            dict[current_key] = token.value
            current_key = nil
          elsif token.type == "bracket" && token.value == "["
            result = parse_array(tokens, index + 1)
            dict[current_key] = result[:array]
            index = result[:next_index] - 1
            current_key = nil
          elsif token.type == "dict" && token.value == "<<"
            result = parse_dict(tokens, index + 1)
            dict[current_key] = result[:dict]
            index = result[:next_index] - 1
            current_key = nil
          elsif token.type == "brace" && token.value == "{"
            result = parse_procedure(tokens, index + 1)
            dict[current_key] = { type: "procedure", body: result[:procedure] }
            index = result[:next_index] - 1
            current_key = nil
          end
        end

        index += 1
      end

      { dict: dict, next_index: index }
    end

    def execute_operator(op, tokens, current_index)
      # Check if operator is defined in dictionary
      dict_val = lookup_name(op)
      if dict_val
        if dict_val.is_a?(Hash) && dict_val[:type] == "procedure"
          execute_procedure(tokens, dict_val[:body], current_index)
        else
          @stack << dict_val
        end
        return
      end

      # Execute built-in operators
      case op
      when "neg" then op_neg
      when "add" then op_add
      when "sub" then op_sub
      when "mul" then op_mul
      when "div" then op_div
      when "exch" then op_exch
      when "dict" then op_dict
      when "begin" then op_begin
      when "end" then op_end
      when "def" then op_def
      when "setdash" then op_setdash
      when "newpath" then op_newpath
      when "moveto" then op_moveto
      when "rmoveto" then op_rmoveto
      when "lineto" then op_lineto(tokens, current_index)
      when "rlineto" then op_rlineto
      when "curveto" then op_curveto
      when "rcurveto" then op_rcurveto
      when "closepath" then op_closepath
      when "stroke" then op_stroke
      when "fill", "eofill", "evenodd" then op_fill
      when "setrgbcolor" then op_setrgbcolor
      when "setgray" then op_setgray
      when "setcmykcolor" then op_setcmykcolor
      when "setlinewidth" then op_setlinewidth
      when "setlinecap" then op_setlinecap
      when "setlinejoin" then op_setlinejoin
      when "translate" then op_translate
      when "scale" then op_scale
      when "rotate" then op_rotate
      when "gsave" then op_gsave
      when "grestore", "restore" then op_grestore
      when "arc" then op_arc
      when "clip" then op_clip
      when "image", "imagemask" then op_image
      when "findfont" then op_findfont
      when "scalefont" then op_scalefont
      when "setfont" then op_setfont
      when "show" then op_show
      when "showpage" then nil # No-op
      when "shfill" then op_shfill
      when "makepattern" then op_makepattern
      when "setpattern" then op_setpattern
      when "setcolorspace", "matrix" then nil # Not implemented
      else
        @svg_out[:element_shapes] << "<!-- Unhandled operator: #{op} -->"
      end
    end

    def execute_procedure(tokens, proc_tokens, current_index)
      tokens.insert(current_index + 1, *proc_tokens)
    end

    def lookup_name(name)
      @dict_stack.reverse_each do |dict|
        return dict[name] if dict.key?(name)
      end
      nil
    end

    def safe_pop_number(default = 0)
      v = @stack.pop
      return v if v.is_a?(Numeric)
      return v.to_f if v.is_a?(String) && v.match?(/^-?\d+\.?\d*$/)

      default
    end

    def num_fmt(n)
      # Format number, removing unnecessary decimals
      if n == n.to_i
        n.to_i.to_s
      else
        format("%.3f", n).sub(/\.?0+$/, "")
      end
    end

    def escape_xml(str)
      str.to_s
        .gsub("&", "&amp;")
        .gsub("<", "&lt;")
        .gsub(">", "&gt;")
        .gsub('"', "&quot;")
        .gsub("'", "&#39;")
    end

    def is_simple_line_ahead?(tokens, start_idx)
      (start_idx...tokens.length).each do |j|
        token = tokens[j]
        next if %w[number name].include?(token.type)

        next unless token.type == "operator"
        return false if STATE_MODIFIERS.include?(token.value)
        return true if PATH_TERMINATORS.include?(token.value)
        return false if PATH_CONTINUATORS.include?(token.value)

        return true
      end
      true
    end

    def flush_path(mode)
      # rubocop:disable-next Style/ZeroLengthPredicate
      return if @path.length.zero?

      d = @path.to_path
      path_str = emit_svg_path(d, @g_state, mode)
      @svg_out[:element_shapes] << path_str
      @path = @path.reset
    end

    def emit_svg_path(d, g_state, mode, fill_id = nil)
      need_group = !g_state[:ctm].identity? || !g_state[:clip_stack].empty?

      decomp = g_state[:ctm].decompose
      transform_str = ""
      unless g_state[:ctm].identity?
        parts = []
        tx = decomp[:translate]
        parts << "translate(#{num_fmt(tx[:x])} #{num_fmt(tx[:y])})" if tx[:x].abs > 1e-6 || tx[:y].abs > 1e-6
        parts << "rotate(#{num_fmt(decomp[:rotate])})" if decomp[:rotate].abs > 1e-6
        sc = decomp[:scale]
        parts << "scale(#{num_fmt(sc[:x])} #{num_fmt(sc[:y])})" if (sc[:x] - 1).abs > 1e-6 || (sc[:y] - 1).abs > 1e-6
        transform_str = parts.join(" ")
      end

      fill_color = mode[:fill] ? (g_state[:fill] || "black") : "none"
      stroke_color = mode[:stroke] ? (g_state[:stroke] || "black") : "none"

      path_attrs = ["d=\"#{d}\""]

      path_attrs << if fill_id
                      "fill=\"url(##{fill_id})\""
                    else
                      "fill=\"#{fill_color}\""
                    end

      if mode[:stroke] && stroke_color != "none"
        path_attrs << "stroke=\"#{stroke_color}\""
        if g_state[:stroke_width] && g_state[:stroke_width] != 1
          path_attrs << "stroke-width=\"#{g_state[:stroke_width]}\""
        end
        path_attrs << "stroke-linecap=\"#{g_state[:line_cap]}\"" if g_state[:line_cap] && g_state[:line_cap] != "butt"
        if g_state[:line_join] && g_state[:line_join] != "miter"
          path_attrs << "stroke-linejoin=\"#{g_state[:line_join]}\""
        end
        path_attrs << "stroke-dasharray=\"#{g_state[:dash]}\"" if g_state[:dash] && !g_state[:dash].to_s.empty?
      elsif mode[:fill] && fill_color != "none"
        path_attrs << "stroke=\"none\""
      end

      path_attrs_str = path_attrs.join(" ")
      clip_id = g_state[:clip_stack].empty? ? "" : " clip-path=\"url(#clip#{g_state[:clip_stack].length - 1})\""

      if need_group
        "<g transform=\"#{transform_str}\"#{clip_id}><path #{path_attrs_str} /></g>"
      else
        "<path #{path_attrs_str}#{clip_id} />"
      end
    end

    # Operator implementations
    def op_neg
      v = @stack.pop
      @stack << if v.is_a?(Numeric)
                  -v
                elsif v.is_a?(String) && v.match?(/^-?\d+\.?\d*$/)
                  -v.to_f
                else
                  0
                end
    end

    def op_add
      b = safe_pop_number(0)
      a = safe_pop_number(0)
      @stack << (a + b)
    end

    def op_sub
      b = safe_pop_number(0)
      a = safe_pop_number(0)
      @stack << (a - b)
    end

    def op_mul
      b = safe_pop_number(1)
      a = safe_pop_number(1)
      @stack << (a * b)
    end

    def op_div
      b = safe_pop_number(1)
      a = safe_pop_number(0)
      @stack << (b.zero? ? 0 : a / b)
    end

    def op_exch
      b = @stack.pop
      a = @stack.pop
      @stack << b
      @stack << a
    end

    def op_dict
      safe_pop_number(0)
      @stack << {}
    end

    def op_begin
      d = @stack.pop
      @dict_stack << if d.is_a?(Hash)
                       d
                     else
                       {}
                     end
    end

    def op_end
      @dict_stack.pop if @dict_stack.length > 1
    end

    def op_def
      value = @stack.pop
      key = @stack.pop
      @dict_stack.last[key.to_s] = value if key
    end

    def op_setdash
      safe_pop_number(0)
      arr = @stack.pop
      @g_state[:dash] = if arr.is_a?(Array)
                          arr.map { |v| num_fmt(v.to_f) }.join(" ")
                        elsif arr.is_a?(Numeric)
                          num_fmt(arr.to_f)
                        end
    end

    def op_newpath
      @path = @path.reset
    end

    def op_moveto
      y = safe_pop_number(0)
      x = safe_pop_number(0)
      @path.move_to(x, y)
      @current_x = x
      @current_y = y
      @g_state[:last_text_pos] = { x: x, y: y }
    end

    def op_rmoveto
      dy = safe_pop_number(0)
      dx = safe_pop_number(0)
      @path.move_to_rel(dx, dy)
      @current_x += dx
      @current_y += dy
      @g_state[:last_text_pos] = { x: @current_x, y: @current_y }
    end

    def op_lineto(tokens, current_index)
      y = safe_pop_number(0)
      x = safe_pop_number(0)
      @path.line_to(x, y)
      @current_x = x
      @current_y = y

      # Check if simple line
      if @path.parts.length == 2 &&
          @path.parts[0].start_with?("M ") &&
          @path.parts[1].start_with?("L ") &&
          is_simple_line_ahead?(tokens, current_index + 1)
        flush_path(STROKE_ONLY)
        @path = @path.reset
      end
    end

    def op_rlineto
      dy = safe_pop_number(0)
      dx = safe_pop_number(0)
      @path.line_to_rel(dx, dy)
      @current_x += dx
      @current_y += dy
    end

    def op_curveto
      y = safe_pop_number(0)
      x = safe_pop_number(0)
      y2 = safe_pop_number(0)
      x2 = safe_pop_number(0)
      y1 = safe_pop_number(0)
      x1 = safe_pop_number(0)
      @path.curve_to(x1, y1, x2, y2, x, y)
      @current_x = x
      @current_y = y
    end

    def op_rcurveto
      dy = safe_pop_number(0)
      dx = safe_pop_number(0)
      dy2 = safe_pop_number(0)
      dx2 = safe_pop_number(0)
      dy1 = safe_pop_number(0)
      dx1 = safe_pop_number(0)
      @path.curve_to_rel(dx1, dy1, dx2, dy2, dx, dy)
      @current_x += dx
      @current_y += dy
    end

    def op_closepath
      return unless @path.length.positive? && !@path.parts.last&.end_with?("Z")

      @path.close
    end

    def op_stroke
      flush_path(STROKE_ONLY)
      @path = @path.reset
    end

    def op_fill
      flush_path(FILL_ONLY)
      @path = @path.reset
    end

    def op_setrgbcolor
      b = safe_pop_number(0)
      g = safe_pop_number(0)
      r = safe_pop_number(0)
      rgb = Colors.color2rgb([r, g, b])
      @g_state[:fill] = rgb
      @g_state[:stroke] = rgb
      @g_state[:pattern] = nil
      @g_state[:pattern_dict] = nil
    end

    def op_setgray
      v = safe_pop_number(0)
      rgb = Colors.gray2rgb(v)
      @g_state[:fill] = rgb
      @g_state[:stroke] = rgb
      @g_state[:pattern] = nil
      @g_state[:pattern_dict] = nil
    end

    def op_setcmykcolor
      k = safe_pop_number(0)
      y = safe_pop_number(0)
      m = safe_pop_number(0)
      c = safe_pop_number(0)
      rgb = Colors.cmyk2rgb([c, m, y, k])
      @g_state[:fill] = rgb
      @g_state[:stroke] = rgb
      @g_state[:pattern] = nil
      @g_state[:pattern_dict] = nil
    end

    def op_setlinewidth
      @g_state[:stroke_width] = safe_pop_number(1)
    end

    def op_setlinecap
      v = @stack.pop
      if v.is_a?(Numeric)
        @g_state[:line_cap] = if v.zero?
                                "butt"
                              else
                                v == 1 ? "round" : "square"
                              end
      elsif v.is_a?(String)
        @g_state[:line_cap] = v
      end
    end

    def op_setlinejoin
      v = @stack.pop
      if v.is_a?(Numeric)
        @g_state[:line_join] = if v.zero?
                                 "miter"
                               elsif v == 1
                                 "round"
                               elsif v == 2
                                 "bevel"
                               else
                                 v == 3 ? "arcs" : "miter"
                               end
      elsif v.is_a?(String)
        @g_state[:line_join] = v
      end
    end

    def op_translate
      ty = safe_pop_number(0)
      tx = safe_pop_number(0)
      @g_state[:ctm] = @g_state[:ctm].translate(tx, ty)
      update_path_transform_mode
    end

    def op_scale
      sy = safe_pop_number(1)
      sx = safe_pop_number(1)
      @g_state[:ctm] = @g_state[:ctm].scale(sx, sy)
      update_path_transform_mode
    end

    def op_rotate
      angle = safe_pop_number(0)
      @g_state[:ctm] = @g_state[:ctm].rotate(angle)
      update_path_transform_mode
    end

    def op_gsave
      @g_stack << clone_graphic_state(@g_state)
    end

    def op_grestore
      return if @g_stack.empty?

      st = @g_stack.pop
      return unless st

      if st[:clip_stack].length > @g_state[:clip_stack].length
        (@g_state[:clip_stack].length...st[:clip_stack].length).each do |j|
          clip_path = st[:clip_stack][j]
          @svg_out[:defs] << "<clipPath id=\"clip#{@id_counter}\"><path d=\"#{clip_path}\" /></clipPath>"
          @id_counter += 1
        end
      end

      @g_state = st
      update_path_transform_mode
    end

    def op_arc
      ang2 = safe_pop_number(0)
      ang1 = safe_pop_number(0)
      r = safe_pop_number(0)
      y = safe_pop_number(0)
      x = safe_pop_number(0)

      need_group = !@g_state[:ctm].identity? || !@g_state[:clip_stack].empty?
      if need_group
        rx = r.abs
        ry = r.abs
      else
        scale_x = Math.hypot(@g_state[:ctm].a, @g_state[:ctm].b) || 1
        scale_y = Math.hypot(@g_state[:ctm].c, @g_state[:ctm].d) || 1
        rx = (r * scale_x).abs
        ry = (r * scale_y).abs
      end

      start_rad = ang1 * Math::PI / 180.0
      start = { x: x + (r * Math.cos(start_rad)),
                y: y + (r * Math.sin(start_rad)) }
      end_rad = ang2 * Math::PI / 180.0
      end_point = { x: x + (r * Math.cos(end_rad)),
                    y: y + (r * Math.sin(end_rad)) }

      delta = (ang2 - ang1).abs
      is_full_circle = (delta - 360).abs < 1e-6 || delta.abs < 1e-6

      # Replace last moveTo if it's to the center
      @path.parts.pop if @path.parts.last&.start_with?("M ")

      @path.move_to(start[:x], start[:y])

      if is_full_circle
        mid_rad = (ang1 + 180) % 360
        mid = { x: x + (r * Math.cos(mid_rad * Math::PI / 180.0)),
                y: y + (r * Math.sin(mid_rad * Math::PI / 180.0)) }
        @path.ellipse_to(rx, ry, 0, 1, 1, mid[:x], mid[:y])
        @path.ellipse_to(rx, ry, 0, 1, 1, start[:x], start[:y])
        @path.close
      else
        normalized_delta = (((ang2 - ang1) % 360) + 360) % 360
        large_arc = normalized_delta > 180 ? 1 : 0
        sweep = normalized_delta.positive? ? 1 : 0
        @path.ellipse_to(rx, ry, 0, large_arc, sweep, end_point[:x],
                         end_point[:y])
      end
      @current_x = end_point[:x]
      @current_y = end_point[:y]
    end

    def op_clip
      return unless @path.length.positive?

      clip_path = @path.to_path
      clip_id = "clip#{@id_counter}"
      @svg_out[:defs] << "<clipPath id=\"#{clip_id}\"><path d=\"#{clip_path}\" /></clipPath>"
      @id_counter += 1
      @g_state[:clip_stack] << clip_path
      @path = @path.reset
    end

    def op_image
      @svg_out[:element_shapes] << "<!-- image/imagemask not implemented -->\n" \
                                   "<image transform=\"scale(1 -1)\" x=\"10\" y=\"-320\" " \
                                   "width=\"50\" height=\"50\" href=\"#{DEFAULT_IMAGE}\" />"
    end

    def op_findfont
      fname = @stack.pop
      @stack << { font: fname.to_s }
    end

    def op_scalefont
      size = safe_pop_number(0)
      font_obj = @stack.pop
      if font_obj.is_a?(Hash)
        font_obj[:size] = size
        @stack << font_obj
      else
        @stack << { font: font_obj.to_s, size: size }
      end
    end

    def op_setfont
      s_font = @stack.pop
      if s_font.is_a?(Hash)
        @g_state[:font] = s_font[:font] || @g_state[:font]
        @g_state[:font_size] = s_font[:size] || @g_state[:font_size]
      elsif s_font.is_a?(String)
        @g_state[:font] = s_font
      end
    end

    def op_show
      s = @stack.pop.to_s
      escaped = escape_xml(s)
      if @g_state[:last_text_pos]
        p = @g_state[:ctm].apply_point(@g_state[:last_text_pos][:x],
                                       @g_state[:last_text_pos][:y])
        @svg_out[:element_shapes] << "<text transform=\"scale(1 -1)\" " \
                                     "x=\"#{num_fmt(p[:x])}\" y=\"#{num_fmt(-p[:y])}\" " \
                                     "font-family=\"#{@g_state[:font]}\" " \
                                     "font-size=\"#{num_fmt(@g_state[:font_size])}\" " \
                                     "fill=\"#{@g_state[:fill] || 'black'}\" " \
                                     "stroke=\"none\">#{escaped}</text>"
      end
      @path = @path.reset
      @g_state[:last_text_pos] = nil
    end

    def op_shfill
      shading = @stack.pop
      return unless shading.is_a?(Hash)

      grad_id = "grad#{@id_counter}"
      @id_counter += 1

      if shading["ShadingType"] == 2
        # Linear gradient
        coords = shading["Coords"]
        c0 = Colors.color2rgb(shading.dig("Function", "C0") || [1, 1, 1])
        c1 = Colors.color2rgb(shading.dig("Function", "C1") || [0, 0, 0])

        x1, y1, x2, y2 = coords

        @svg_out[:defs] << "<linearGradient id=\"#{grad_id}\" " \
                           "x1=\"#{num_fmt(x1)}%\" y1=\"#{num_fmt(y1)}%\" " \
                           "x2=\"#{num_fmt(x2)}%\" y2=\"#{num_fmt(y2)}%\">\n" \
                           "<stop offset=\"0\" stop-color=\"#{c0}\" />\n" \
                           "<stop offset=\"1\" stop-color=\"#{c1}\" />\n" \
                           "</linearGradient>"

        min_x = [x1, x2].min
        min_y = [y1, y2].min
        width = (x2 - x1).abs
        height = (y2 - y1).abs

        d = "M #{min_x} #{min_y} L #{min_x + width} #{min_y} " \
            "L #{min_x + width} #{min_y + height} L #{min_x} #{min_y + height} Z"
        @svg_out[:element_shapes] << emit_svg_path(d, @g_state, FILL_ONLY,
                                                   grad_id)
        @path = @path.reset
      elsif shading["ShadingType"] == 3
        # Radial gradient
        coords = shading["Coords"]
        c0 = Colors.color2rgb(shading.dig("Function", "C0") || [1, 1, 1])
        c1 = Colors.color2rgb(shading.dig("Function", "C1") || [0, 0, 0])

        _, _, _, cx, cy, r = coords

        @svg_out[:defs] << "<radialGradient id=\"#{grad_id}\">\n" \
                           "<stop offset=\"0\" stop-color=\"#{c0}\" />\n" \
                           "<stop offset=\"1\" stop-color=\"#{c1}\" />\n" \
                           "</radialGradient>"

        d = "M #{num_fmt(cx + r)} #{num_fmt(cy)} " \
            "A #{num_fmt(r)} #{num_fmt(r)} 0 1 1 #{num_fmt(cx - r)} #{num_fmt(cy)} " \
            "A #{num_fmt(r)} #{num_fmt(r)} 0 1 1 #{num_fmt(cx + r)} #{num_fmt(cy)} Z"

        @svg_out[:element_shapes] << emit_svg_path(d, @g_state, FILL_ONLY,
                                                   grad_id)
        @path = @path.reset
      else
        @svg_out[:element_shapes] << "<!-- shfill not fully implemented -->"
      end
    end

    def op_makepattern
      dict = @stack.pop
      return unless dict.is_a?(Hash)

      pattern_id = "pattern#{@id_counter}"
      @id_counter += 1

      bbox = dict["BBox"] || [0, 0, 20, 20]
      x_step = dict["XStep"] || 20
      y_step = dict["YStep"] || 20
      if dict["PaintProc"].is_a?(Hash) && dict["PaintProc"][:body]
        # Interpret the PaintProc procedure
        paint_proc_tokens = dict["PaintProc"][:body]

        # Create sub-interpreter for pattern
        sub_interp = Interpreter.new
        paint_proc_out = sub_interp.interpret(paint_proc_tokens)

        # Extract path elements
        paint_proc_path = paint_proc_out[:element_shapes]
          .select { |s| s.start_with?("<path") }
          .join("\n")

        pattern_defs = "<pattern id=\"#{pattern_id}\" " \
                       "x=\"#{bbox[0]}\" y=\"#{bbox[1]}\" " \
                       "width=\"#{x_step}\" height=\"#{y_step}\" " \
                       "patternUnits=\"userSpaceOnUse\">\n" \
                       "#{paint_proc_path}\n" \
                       "</pattern>"

        @svg_out[:defs] << pattern_defs
      end

      @stack << {
        type: "pattern",
        id: pattern_id,
        dict: dict,
      }
    end

    def op_setpattern
      pattern = @stack.pop

      if pattern.is_a?(Hash) && pattern[:type] == "pattern"
        @g_state[:fill] = "url(##{pattern[:id]})"
        @g_state[:pattern] = pattern[:id]
        @g_state[:pattern_dict] = pattern[:dict]
      else
        @g_state[:fill] = "none"
        @g_state[:pattern] = nil
        @g_state[:pattern_dict] = nil
      end
    end
  end
end
