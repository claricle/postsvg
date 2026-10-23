# frozen_string_literal: true

require "spec_helper"

RSpec.describe "SVG path commands" do # rubocop:disable RSpec/DescribeClass
  def svg_path(data)
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <path d="#{data}" fill="none" stroke="black"/>
      </svg>
    SVG
  end

  {
    "M10 10 V50" => "10 50 lineto",
    "M10 10 v20" => "0 20 rlineto",
    "M10 10 H50" => "50 10 lineto",
    "M10 10 h20" => "20 0 rlineto",
    "M10 10 t10,0" => "10 10 13.3333 10 20 10 curveto",
    "M10 10 T20,10" => "10 10 13.3333 10 20 10 curveto",
    "M10 10 q15,30 30,0 t30,0" => "50 -10 60 -10 70 10 curveto",
    "M10 10 Q25,40 40,10 T70,10" => "50 -10 60 -10 70 10 curveto",
  }.each do |data, operator|
    it "emits the expected coordinates for #{data}" do
      expect(Postsvg.to_ps(svg_path(data)).split.join(" ")).to include(operator)
    end

    it "preserves the geometry of #{data} through PostScript" do
      source = svg_path(data)

      expect(RoundTrip::SvgSummary.call(Postsvg.to_svg(Postsvg.to_ps(source))))
        .to eq(RoundTrip::SvgSummary.call(source))
    end
  end

  it "tracks the endpoint across successive relative smooth quadratics and a line" do
    source = svg_path("M10 10 q15,30 30,0 t30,0 t-30,0 v20")

    expect(RoundTrip::SvgSummary.call(Postsvg.to_svg(Postsvg.to_ps(source))))
      .to eq(RoundTrip::SvgSummary.call(source))
  end
end
