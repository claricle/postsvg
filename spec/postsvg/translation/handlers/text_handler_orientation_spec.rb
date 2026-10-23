# frozen_string_literal: true

require "spec_helper"

RSpec.describe Postsvg::Translation::Handlers::TextHandler do
  def source(transform: "")
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <g transform="#{transform}">
          <text x="10" y="20" font-family="Helvetica" font-size="12" fill="black">F</text>
        </g>
        <rect x="2" y="3" width="4" height="5" fill="black"/>
      </svg>
    SVG
  end

  # Inspect the executed PS state before show, rather than the SVG renderer:
  # its text output discards the CTM's effect on glyph orientation.
  def text_points(svg, eps:)
    program = Postscript::Source.parse(Postsvg.to_ps(svg, eps: eps))
    visitor = Postsvg::Visitors::PsVisitor.new(builder: Postsvg::SvgBuilder.new)
    program.body.each do |statement|
      break if statement.is_a?(Postscript::Model::Operators::Font::Show)

      statement.accept(visitor, nil)
    end
    state = visitor.graphics.current
    x, y = state.last_text_position.values_at(:x, :y)
    [[x, y], [x, y + state.font_size], [x + state.font_size, y]].map do |point|
      state.ctm.apply_point(*point).values_at(:x, :y)
    end
  end

  [false, true].each do |eps|
    it "keeps PS glyphs upright and the baseline positioned with eps=#{eps}" do
      expect(text_points(source, eps: eps)).to eq([[10, 80], [10, 92], [22, 80]])
    end

    it "preserves authored text rotation with eps=#{eps}" do
      points = text_points(source(transform: "translate(40 7) rotate(90)"), eps: eps)

      points.zip([[20, 83], [32, 83], [20, 71]]).each do |actual, expected|
        expect(actual).to match(expected.map { |value| be_within(0.0001).of(value) })
      end
    end
  end

  it "preserves the text baseline and following shape through an SVG round trip" do
    svg = source

    expect(RoundTrip::SvgSummary.call(Postsvg.to_svg(Postsvg.to_ps(svg))))
      .to eq(RoundTrip::SvgSummary.call(svg))
  end
end
