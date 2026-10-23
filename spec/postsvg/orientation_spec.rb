# frozen_string_literal: true

require "spec_helper"

RSpec.describe "SVG round-trip orientation" do # rubocop:disable RSpec/DescribeClass
  def rectangle(y:, attributes: 'viewBox="0 0 100 100"', transform: nil)
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" #{attributes}>
        <g transform="#{transform}"><rect x="0" y="#{y}" width="10" height="10"/></g>
      </svg>
    SVG
  end

  def commands(svg)
    RoundTrip::SvgSummary.call(svg).first.fetch(:geometry).fetch(:commands)
  end

  [0, 20].product([false, true]).each do |y, eps|
    it "keeps the rectangle at y=#{y} after an #{eps ? 'EPS' : 'PS'} round trip" do
      result = Postsvg.to_svg(Postsvg.to_ps(rectangle(y: y), eps: eps))

      expect(commands(result)).to eq([
                                       ["M", 0, y], ["L", 10, y],
                                       ["L", 10, y + 10], ["L", 0, y + 10], ["Z"]
                                     ])
    end
  end

  it "preserves orientation when the viewport uses width and height" do
    source = rectangle(y: 20, attributes: 'width="100" height="100"')

    expect(commands(Postsvg.to_svg(Postsvg.to_ps(source)))).to eq(commands(source))
  end

  it "includes an authored y-flip in document-space geometry" do
    source = rectangle(y: 0, transform: "translate(0 100) scale(1 -1)")

    expect(commands(source)).to eq([
                                     ["M", 0, 100], ["L", 10, 100],
                                     ["L", 10, 90], ["L", 0, 90], ["Z"]
                                   ])
  end

  it "distinguishes an upside-down rectangle from the original" do
    source = rectangle(y: 0)
    flipped = rectangle(y: 0, transform: "translate(0 100) scale(1 -1)")

    expect(RoundTrip::SvgSummary.call(flipped)).not_to eq(RoundTrip::SvgSummary.call(source))
  end
end
