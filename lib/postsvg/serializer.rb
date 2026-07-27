# frozen_string_literal: true

module Postsvg
  # Model::Program -> PostScript source text. Walks the program's
  # header (DSC comments) and body (Model records), emitting each as
  # PS source. Used by the SVG -> PS direction and by tests.
  #
  # OCP: adding serialization for a new operator class means adding
  # one +emit_<keyword>+ method (or falling through to the default
  # keyword+operands emitter). No switch edits.
  class Serializer
    DEFAULT_LANGUAGE_LEVEL = 3
    DEFAULT_CREATOR = "Postsvg #{::Postsvg::VERSION}".freeze

    def self.call(program, eps: false, creator: DEFAULT_CREATOR, **_options)
      new(program, eps: eps, creator: creator).call
    end

    attr_reader :program, :eps, :creator

    def initialize(program, eps:, creator:)
      raise ArgumentError, "program must be a Model::Program" unless program.is_a?(Model::Program)

      @program = program
      @eps = eps
      @creator = creator
    end

    def call
      buffer = String.new(capacity: 4096)
      emit_header(buffer)
      emit_body(buffer)
      buffer << "showpage\n"
      buffer << "%%EOF\n"
      buffer
    end

    # All methods below this point are public. They are intentionally
    # exposed (prefixed +emit_+) so dispatch can reach them via
    # +method_defined?+ without +respond_to?+.
    def emit_header(buffer)
      buffer << "%!PS-Adobe-#{DEFAULT_LANGUAGE_LEVEL}.0"
      buffer << " EPSF-3.0" if eps
      buffer << "\n"
      buffer << "%%Creator: #{creator}\n"
      bbox = program.header.bounding_box
      if bbox && !bbox.empty?
        buffer << "%%BoundingBox: " << bbox.map { |v| FormatNumber.call(v) }.join(" ") << "\n"
      end
      if program.header.title
        buffer << "%%Title: #{program.header.title}\n"
      end
      buffer << "%%LanguageLevel: #{DEFAULT_LANGUAGE_LEVEL}\n"
      buffer << "%%EndComments\n"
    end

    def emit_body(buffer)
      program.body.each do |statement|
        emit_statement(statement, buffer)
      end
    end

    def emit_statement(statement, buffer)
      case statement
      when Model::Literals::Number
        buffer << FormatNumber.call(statement.value) << "\n"
      when Model::Literals::Name
        prefix = statement.literal? ? "/" : ""
        buffer << prefix << statement.value << "\n"
      when Model::Literals::StringLiteral
        buffer << escape_string(statement.value) << "\n"
      when Model::Literals::HexLiteral
        buffer << "<" << statement.value << ">\n"
      when Model::Literals::ArrayLiteral
        buffer << "[ "
        statement.elements.each { |e| emit_inline(e, buffer); buffer << " " }
        buffer << "]\n"
      when Model::Literals::Procedure
        buffer << "{\n"
        statement.body.each { |s| emit_statement(s, buffer) }
        buffer << "}\n"
      when Model::Literals::Dictionary
        buffer << "<<\n"
        statement.entries.each do |k, v|
          buffer << "/#{k} "
          emit_inline(v, buffer)
          buffer << "\n"
        end
        buffer << ">>\n"
      when Model::Operator
        emit_operator(statement, buffer)
      when Model::UnknownOperator
        buffer << "% unhandled operator: #{statement.keyword}\n"
      when Model::InvokeProcedure
        buffer << statement.name << "\n"
      end
    end

    def emit_inline(statement, buffer)
      case statement
      when Model::Literals::Number then buffer << FormatNumber.call(statement.value)
      when Model::Literals::Name then buffer << (statement.literal? ? "/" : "") << statement.value
      when Model::Literals::StringLiteral then buffer << escape_string(statement.value)
      when Model::Literals::HexLiteral then buffer << "<" << statement.value << ">"
      else buffer << statement.class.name.to_s
      end
    end

    # Dispatch table: emit_<keyword>. Falls back to the generic
    # operand+keyword form when no specific method exists.
    def emit_operator(operator, buffer)
      method = :"emit_#{operator.visit_name}"
      if self.class.public_method_defined?(method)
        public_send(method, operator, buffer)
      else
        emit_generic_operator(operator, buffer)
      end
    end

    def emit_generic_operator(operator, buffer)
      buffer << operator.keyword << "\n"
    end

    # Path
    def emit_moveto(op, buf)
      buf << "#{FormatNumber.call(op.x)} #{FormatNumber.call(op.y)} moveto\n"
    end

    def emit_rmoveto(op, buf)
      buf << "#{FormatNumber.call(op.dx)} #{FormatNumber.call(op.dy)} rmoveto\n"
    end

    def emit_lineto(op, buf)
      buf << "#{FormatNumber.call(op.x)} #{FormatNumber.call(op.y)} lineto\n"
    end

    def emit_rlineto(op, buf)
      buf << "#{FormatNumber.call(op.dx)} #{FormatNumber.call(op.dy)} rlineto\n"
    end

    def emit_curveto(op, buf)
      buf << "#{FormatNumber.call(op.x1)} #{FormatNumber.call(op.y1)} " \
            "#{FormatNumber.call(op.x2)} #{FormatNumber.call(op.y2)} " \
            "#{FormatNumber.call(op.x3)} #{FormatNumber.call(op.y3)} curveto\n"
    end

    def emit_rcurveto(op, buf)
      buf << "#{FormatNumber.call(op.dx1)} #{FormatNumber.call(op.dy1)} " \
            "#{FormatNumber.call(op.dx2)} #{FormatNumber.call(op.dy2)} " \
            "#{FormatNumber.call(op.dx3)} #{FormatNumber.call(op.dy3)} rcurveto\n"
    end

    def emit_arc(op, buf)
      buf << "#{FormatNumber.call(op.x)} #{FormatNumber.call(op.y)} " \
            "#{FormatNumber.call(op.radius)} " \
            "#{FormatNumber.call(op.angle1)} #{FormatNumber.call(op.angle2)} arc\n"
    end

    def emit_arcn(op, buf)
      buf << "#{FormatNumber.call(op.x)} #{FormatNumber.call(op.y)} " \
            "#{FormatNumber.call(op.radius)} " \
            "#{FormatNumber.call(op.angle1)} #{FormatNumber.call(op.angle2)} arcn\n"
    end

    def emit_closepath(_op, buf)
      buf << "closepath\n"
    end

    def emit_newpath(_op, buf)
      buf << "newpath\n"
    end

    # Painting
    def emit_stroke(_op, buf) = buf << "stroke\n"
    def emit_fill(_op, buf) = buf << "fill\n"
    def emit_eofill(_op, buf) = buf << "eofill\n"
    def emit_clip(_op, buf) = buf << "clip\n"
    def emit_eoclip(_op, buf) = buf << "eoclip\n"

    # Color
    def emit_setrgbcolor(op, buf)
      buf << "#{FormatNumber.call(op.red)} #{FormatNumber.call(op.green)} #{FormatNumber.call(op.blue)} setrgbcolor\n"
    end

    def emit_setgray(op, buf)
      buf << "#{FormatNumber.call(op.gray)} setgray\n"
    end

    def emit_setcmykcolor(op, buf)
      buf << "#{FormatNumber.call(op.cyan)} #{FormatNumber.call(op.magenta)} " \
            "#{FormatNumber.call(op.yellow)} #{FormatNumber.call(op.key)} setcmykcolor\n"
    end

    def emit_sethsbcolor(op, buf)
      buf << "#{FormatNumber.call(op.hue)} #{FormatNumber.call(op.saturation)} " \
            "#{FormatNumber.call(op.brightness)} sethsbcolor\n"
    end

    # Graphics state
    def emit_gsave(_op, buf) = buf << "gsave\n"
    def emit_grestore(_op, buf) = buf << "grestore\n"
    def emit_grestoreall(_op, buf) = buf << "grestoreall\n"

    def emit_setlinewidth(op, buf)
      buf << "#{FormatNumber.call(op.width)} setlinewidth\n"
    end

    def emit_setlinecap(op, buf)
      buf << "#{op.cap_code} setlinecap\n"
    end

    def emit_setlinejoin(op, buf)
      buf << "#{op.join_code} setlinejoin\n"
    end

    def emit_setmiterlimit(op, buf)
      buf << "#{FormatNumber.call(op.limit)} setmiterlimit\n"
    end

    def emit_setdash(op, buf)
      pattern_str =
        case op.pattern
        when Array then "[#{op.pattern.map { |v| FormatNumber.call(v.to_f) }.join(' ')}]"
        when Numeric then FormatNumber.call(op.pattern.to_f)
        else "[]"
        end
      buf << "#{pattern_str} #{FormatNumber.call(op.offset)} setdash\n"
    end

    # Transformations
    def emit_translate(op, buf)
      buf << "#{FormatNumber.call(op.tx)} #{FormatNumber.call(op.ty)} translate\n"
    end

    def emit_scale(op, buf)
      buf << "#{FormatNumber.call(op.sx)} #{FormatNumber.call(op.sy)} scale\n"
    end

    def emit_rotate(op, buf)
      buf << "#{FormatNumber.call(op.angle)} rotate\n"
    end

    def emit_concat(op, buf)
      m = op.matrix
      arr = m.is_a?(Array) ? m : [m.a, m.b, m.c, m.d, m.e, m.f]
      buf << "[#{arr.map { |v| FormatNumber.call(v.to_f) }.join(' ')}] concat\n"
    end

    def escape_string(text)
      escaped = text.to_s.gsub(/[\(\)\\]/) { |c| "\\#{c}" }
                          .gsub("\n", "\\n")
                          .gsub("\r", "\\r")
                          .gsub("\t", "\\t")
      "(#{escaped})"
    end

    # Font / text
    def emit_findfont(op, buf)
      name = font_name_value(op.name)
      buf << "/#{name} findfont\n"
    end

    def emit_scalefont(op, buf)
      buf << "#{FormatNumber.call(op.size)} scalefont\n"
    end

    def emit_setfont(_op, buf)
      buf << "setfont\n"
    end

    def emit_show(op, buf)
      buf << "#{escape_string(string_value(op.text))} show\n"
    end

    def emit_xyshow(_op, buf)
      buf << "% xyshow: per-glyph advances not serialized\n"
    end

    def emit_stringwidth(_op, buf)
      buf << "% stringwidth: no runtime result captured\n"
    end

    def emit_charpath(_op, buf)
      buf << "% charpath: requires font metrics\n"
    end

    # Container operators
    def emit_length(_op, buf) = buf << "length\n"
    def emit_get(_op, buf) = buf << "get\n"
    def emit_put(_op, buf) = buf << "put\n"
    def emit_getinterval(_op, buf) = buf << "getinterval\n"
    def emit_putinterval(_op, buf) = buf << "putinterval\n"
    def emit_forall(_op, buf) = buf << "forall\n"
    def emit_astore(_op, buf) = buf << "astore\n"
    def emit_search(_op, buf) = buf << "search\n"
    def emit_anchorsearch(_op, buf) = buf << "anchorsearch\n"
    def emit_token(_op, buf) = buf << "token\n"
    def emit_string(_op, buf) = buf << "string\n"
    def emit_cvs(_op, buf) = buf << "cvs\n"

    # Dictionary operators (currentdict etc.)
    def emit_currentdict(_op, buf) = buf << "currentdict\n"
    def emit_countdictstack(_op, buf) = buf << "countdictstack\n"
    def emit_dictstack(_op, buf) = buf << "dictstack\n"
    def emit_maxlength(_op, buf) = buf << "maxlength\n"

    def font_name_value(value)
      case value
      when Model::Literals::Name then value.value
      when Model::Literals::StringLiteral then value.value
      when String then value
      else value.to_s
      end
    end

    def string_value(value)
      case value
      when Model::Literals::StringLiteral then value.value
      when Model::Literals::HexLiteral then value.bytes
      when String then value
      else value.to_s
      end
    end
  end
end
