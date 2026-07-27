# frozen_string_literal: true

require "postsvg"

RSpec.describe "round trip SVG -> PS -> SVG" do
  def round_trip(svg)
    Postsvg.to_svg(Postsvg.to_ps(svg))
  end

  it "preserves a rectangle" do
    svg1 = %{<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect x="10" y="10" width="80" height="80" fill="#808080"/></svg>}
    svg2 = round_trip(svg1)
    expect(svg2).to include("<svg")
    expect(svg2).to include("path")
    expect(svg2).to include("808080")
  end

  it "preserves a circle as an arc" do
    svg1 = %{<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="25" fill="#ff0000"/></svg>}
    svg2 = round_trip(svg1)
    expect(svg2).to include("A 25 25")
  end

  it "preserves viewbox dimensions" do
    svg1 = %{<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="50" height="50"/></svg>}
    svg2 = round_trip(svg1)
    expect(svg2).to include(%(viewBox="0 0 100 100"))
  end
end

RSpec.describe "round trip PS -> SVG -> PS" do
  it "preserves a moveto-lineto-stroke sequence" do
    ps1 = <<~PS
      %!PS-Adobe-3.0 EPSF-3.0
      %%BoundingBox: 0 0 100 100
      newpath
      10 10 moveto
      90 90 lineto
      1 0 0 setrgbcolor
      stroke
    PS
    svg = Postsvg.to_svg(ps1)
    ps2 = Postsvg.to_ps(svg)
    expect(ps2).to include("moveto")
    expect(ps2).to include("lineto")
    expect(ps2).to include("setrgbcolor")
    expect(ps2).to include("stroke")
  end
end
