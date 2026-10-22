# frozen_string_literal: true

require "spec_helper"

RSpec.describe Postsvg::Translation::RecordEmitter do
  it "splices typed font and text operands" do
    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg">
        <text x="10" y="20" font-family="Helvetica" font-size="12">Hi</text>
      </svg>
    SVG

    ps = Postsvg.to_ps(svg)

    expect(ps).to match(%r{/Helvetica\s+findfont})
    expect(ps).to match(/12\s+scalefont/)
    expect(ps).to match(/\(Hi\)\s+show/)
  end

  it "splices a concat matrix as one array literal" do
    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg">
        <g transform="translate(5 5)"><rect width="10" height="10"/></g>
      </svg>
    SVG

    expect(Postsvg.to_ps(svg)).to match(/\[\s+1\s+0\s+0\s+1\s+5\s+5\s+\]\s+concat/)
  end

  it "splices a linecap code" do
    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg">
        <line x1="0" y1="0" x2="10" y2="10" stroke="black" stroke-linecap="butt"/>
      </svg>
    SVG

    expect(Postsvg.to_ps(svg)).to match(/0\s+setlinecap/)
  end

  it "preserves relative moveto offsets through serialization and parsing" do
    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg">
        <path d="M 10 20 m 5 -3 l 10 10" fill="none" stroke="black"/>
      </svg>
    SVG

    ps = Postsvg.to_ps(svg)
    moves = Postscript::Source.parse(ps).body.grep(Postscript::Model::Operators::Path::Rmoveto)

    expect(ps).to match(/5\s+-3\s+rmoveto/)
    expect(moves.map { |move| [move.dx, move.dy] }).to eq([[5, -3]])
  end
end
