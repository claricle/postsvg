# frozen_string_literal: true

require "spec_helper"

RSpec.describe Postsvg::Translation::Handlers::PathHandler do
  def svg_path(data, attributes = "")
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
        <path d="#{data}" fill="none" stroke="#663399" stroke-width="5" #{attributes}/>
      </svg>
    SVG
  end

  {
    "an elliptical arc" => "M 20 70 A 40 30 0 0 1 100 70",
    "lines before and after an arc" => "M 10 80 L 20 70 A 40 30 0 0 1 100 70 l 10 10",
    "a rotated ellipse" => "M 20 70 A 60 40 30 0 1 100 70",
    "a counterclockwise arc" => "M 20 70 A 60 40 25 0 0 100 70",
    "a large counterclockwise arc" => "M 20 70 A 60 40 25 1 0 100 70",
    "a relative elliptical arc" => "M 20 70 a 40 30 0 0 1 80 0",
    "successive elliptical arcs" => "M 20 70 A 40 30 0 0 1 100 70 A 40 20 0 0 1 180 70",
  }.each do |description, data|
    it "preserves #{description} and stroke styling through PS" do
      source = svg_path(data)

      expect(RoundTrip::SvgSummary.call(Postsvg.to_svg(Postsvg.to_ps(source))))
        .to eq(RoundTrip::SvgSummary.call(source))
    end
  end

  {
    "absolute" => "A 20 10 0 0 1 10 50",
    "relative" => "a 20 10 0 0 1 0 0",
  }.each do |kind, arc|
    it "skips an #{kind} arc with coincident endpoints and preserves the following line" do
      source = svg_path("M 10 50 #{arc} L 90 50")

      expect(Postsvg.to_svg(Postsvg.to_ps(source)))
        .to include('d="M 10 50 L 90 50"')
    end
  end

  it "preserves the element transform around the temporary arc transform" do
    source = svg_path("M 20 70 A 60 40 30 0 1 100 70 L 110 80",
                      'transform="translate(5 10) rotate(90) scale(1.5)"')

    expect(RoundTrip::SvgSummary.call(Postsvg.to_svg(Postsvg.to_ps(source))))
      .to eq(RoundTrip::SvgSummary.call(source))
  end
end
