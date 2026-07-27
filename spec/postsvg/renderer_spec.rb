# frozen_string_literal: true

require "postsvg"

RSpec.describe Postsvg::Renderer do
  def render(ps)
    Postsvg.to_svg(ps)
  end

  it "converts a square PS program to SVG" do
    ps = <<~PS
      %!PS-Adobe-3.0 EPSF-3.0
      %%BoundingBox: 0 0 100 100
      newpath
      10 10 moveto
      90 10 lineto
      90 90 lineto
      10 90 lineto
      closepath
      0.5 setgray
      fill
      showpage
    PS
    svg = render(ps)
    expect(svg).to include(%(viewBox="0 0 100 100"))
    expect(svg).to include(%(<path))
    expect(svg).to include(%(fill="#808080"))
    expect(svg).to include("M 10 10 L 90 10 L 90 90 L 10 90 Z")
  end

  it "handles gsave/grestore correctly" do
    ps = <<~PS
      %!PS-Adobe-3.0 EPSF-3.0
      %%BoundingBox: 0 0 100 100
      newpath 0 0 moveto 50 0 lineto 50 50 lineto closepath
      gsave 1 0 0 setrgbcolor fill grestore
      showpage
    PS
    svg = render(ps)
    expect(svg).to include(%(fill="#ff0000"))
  end
end
