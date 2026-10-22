# frozen_string_literal: true

module RoundTrip
  # Runs SVG through the PS serializer/parser boundary and reports normalized
  # records whose keyword or public operand values changed.
  class Harness
    DEFAULT_PARSER = ->(source) { Postscript::Source.parse(source) }

    def self.call(svg, parser: DEFAULT_PARSER)
      new(svg, parser: parser).call
    end

    def initialize(svg, parser: DEFAULT_PARSER)
      @svg = svg
      @parser = parser
    end

    def call
      document = Postsvg::Svg::Parser.call(@svg)
      expected_program = Postsvg::Translation::PsRenderer.call(document)
      source = Postscript::Serializer.call(expected_program)
      actual_program = @parser.call(source)

      diff(Normalizer.call(expected_program), Normalizer.call(actual_program))
    end

    private

    def diff(expected, actual)
      [expected.length, actual.length].max.times.filter_map do |index|
        next if expected[index] == actual[index]

        { index: index, expected: expected[index], actual: actual[index] }
      end
    end
  end
end
