# frozen_string_literal: true

require "spec_helper"

RSpec.describe Postsvg::Visitors::PsVisitor do # rubocop:disable RSpec/SpecFilePathFormat
  # SvgSummary reports document coordinates, including the default A4
  # page flip: PS y=15 becomes SVG y=842-15, with reversed arc sweep.
  {
    "translation left active at paint" => [
      "0 0 moveto 10 10 translate 0 0 5 0 90 arc stroke",
      ["A", 5.0, 5.0, 0.0, 0, 0, 10.0, 827.0],
    ],
    "scale left active at paint" => [
      "0 0 moveto 2 3 scale 0 0 5 0 90 arc stroke",
      ["A", 15.0, 10.0, 90.0, 0, 0, 0.0, 827.0],
    ],
    "another CTM change after construction" => [
      "0 0 moveto 10 10 translate 0 0 5 0 90 arc 20 0 translate stroke",
      ["A", 5.0, 5.0, 0.0, 0, 0, 10.0, 827.0],
    ],
  }.each do |description, (source, expected_arc)|
    it "preserves arc geometry with #{description}" do
      geometry = RoundTrip::SvgSummary.call(Postsvg.to_svg(source)).first.fetch(:geometry)

      expect(geometry.fetch(:commands).last).to eq(expected_arc)
    end
  end

  it "retains the painting CTM for stroke styling" do
    svg = Postsvg.to_svg("0 0 moveto 2 3 scale 0 0 5 0 90 arc 4 setlinewidth stroke")

    expect(svg).to include('transform="scale(2 3)"', 'stroke-width="4"')
  end

  it "consumes temporary arc operands and restores the saved CTM without discarding the path" do
    visitor = described_class.new(builder: Postsvg::SvgBuilder.new)
    visitor.visit_program(Postscript::Source.parse("40 0 moveto"))
    original_stack = visitor.stack.dup
    visitor.visit_program(Postscript::Source.parse(
                            "matrix currentmatrix [1 0 0 1 0 0] concat 40 30 scale " \
                            "0 0 1 0 90 arc setmatrix",
                          ))

    expect(visitor.graphics.current.ctm).to be_identity
    expect(visitor.stack).to eq(original_stack)
    expect(visitor.path.to_path_d).to eq("M 40 0 A 40 30 0 0 1 0 30")
  end

  it "preserves an implicit arc moveto when the temporary ellipse CTM is restored" do
    svg = Postsvg.to_svg(
      "matrix currentmatrix 40 30 scale 0 0 1 0 90 arc setmatrix stroke",
    )

    expect(svg).to include("M 40 0 A 40 30 0 0 1 0 30")
  end

  it "repaints a saved arc in a different CTM without changing its geometry" do
    svg = Postsvg.to_svg(
      "matrix currentmatrix 40 30 scale 0 0 1 0 90 arc setmatrix " \
      "gsave fill grestore 10 10 translate stroke",
    )

    expect(svg).to include("M 40 0 A 40 30 0 0 1 0 30")
    expect(svg).to include("M 30 -10 A 40 30 0 0 1 -10 20")
    expect(RoundTrip::SvgSummary.call(svg).size).to eq(1)
  end
end
