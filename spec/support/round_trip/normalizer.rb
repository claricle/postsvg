# frozen_string_literal: true

module RoundTrip
  # Reduces PostScript programs to the operator values that matter to a
  # round-trip comparison. Only operators are kept: every literal in the body
  # (numbers, names, strings, arrays, procedures, dictionaries) is an operand,
  # and the operator that consumes it carries its value through
  # ATTRIBUTE_READERS, so comparing operators compares the literals too. The
  # serializer's final showpage is a representation detail and is dropped.
  class Normalizer
    ATTRIBUTE_READERS = {
      Postscript::Model::Operators::Path::Moveto => %i[x y],
      Postscript::Model::Operators::Path::Rmoveto => %i[dx dy],
      Postscript::Model::Operators::Path::Lineto => %i[x y],
      Postscript::Model::Operators::Path::Rlineto => %i[dx dy],
      Postscript::Model::Operators::Path::Curveto => %i[x1 y1 x2 y2 x3 y3],
      Postscript::Model::Operators::Path::Rcurveto => %i[dx1 dy1 dx2 dy2 dx3 dy3],
      Postscript::Model::Operators::Path::Arc => %i[x y radius angle1 angle2],
      Postscript::Model::Operators::Path::Arcn => %i[x y radius angle1 angle2],
      Postscript::Model::Operators::Transformations::Translate => %i[tx ty],
      Postscript::Model::Operators::Transformations::Scale => %i[sx sy],
      Postscript::Model::Operators::Transformations::Rotate => %i[angle],
      Postscript::Model::Operators::Transformations::Concat => %i[matrix],
      Postscript::Model::Operators::Transformations::Setmatrix => %i[matrix],
      Postscript::Model::Operators::Font::Findfont => %i[name],
      Postscript::Model::Operators::Font::Scalefont => %i[font size],
      Postscript::Model::Operators::Font::Setfont => %i[font],
      Postscript::Model::Operators::Font::Show => %i[text],
      Postscript::Model::Operators::Font::Xyshow => %i[text dx dy],
      Postscript::Model::Operators::Font::Stringwidth => %i[text],
      Postscript::Model::Operators::Font::Charpath => %i[text stroke],
      Postscript::Model::Operators::GraphicsState::Setlinewidth => %i[width],
      Postscript::Model::Operators::GraphicsState::Setlinecap => %i[cap_code],
      Postscript::Model::Operators::GraphicsState::Setlinejoin => %i[join_code],
      Postscript::Model::Operators::GraphicsState::Setmiterlimit => %i[limit],
      Postscript::Model::Operators::GraphicsState::Setdash => %i[pattern offset],
      Postscript::Model::Operators::Color::Setgray => %i[gray],
      Postscript::Model::Operators::Color::Setrgbcolor => %i[red green blue],
      Postscript::Model::Operators::Color::Setcmykcolor => %i[cyan magenta yellow key],
      Postscript::Model::Operators::Color::Sethsbcolor => %i[hue saturation brightness],
    }.freeze

    def self.call(program)
      new(program).call
    end

    def initialize(program)
      @program = program
    end

    def call
      records = @program.respond_to?(:body) ? @program.body : @program
      normalized = records.filter_map { |record| normalize_record(record) }
      normalized.pop if normalized.last&.first == "showpage"
      normalized
    end

    private

    def normalize_record(record)
      return unless record.is_a?(Postscript::Model::Operator)

      readers = ATTRIBUTE_READERS.fetch(record.class, [])
      attributes = readers.to_h do |reader|
        [reader, normalize_value(record.public_method(reader).call)]
      end
      [record.keyword, attributes]
    end

    def normalize_value(value)
      case value
      when Postscript::Model::Literals::Number,
           Postscript::Model::Literals::Name,
           Postscript::Model::Literals::StringLiteral
        normalize_value(value.value)
      when Postscript::Model::Literals::ArrayLiteral
        normalize_value(value.elements)
      when Postscript::Model::Computed
        :computed
      when Array
        value.map { |item| normalize_value(item) }
      when Float
        # Postscript::FormatNumber writes 4 decimals; rounding coarser than
        # that would turn 0.32549 vs a parsed 0.3255 into a false difference.
        value.round(4)
      else
        value
      end
    end
  end
end
