# frozen_string_literal: true

require "postsvg"

# rubocop:disable-next RSpec/SpecFilePathFormat
RSpec.describe Postsvg::Visitors::PsVisitor do
  it "restores the current path after filling inside gsave" do
    ps = <<~PS
      %!PS-Adobe-3.0 EPSF-3.0
      %%BoundingBox: 0 0 10 10
      newpath 0 0 moveto 10 0 lineto 10 10 lineto closepath
      gsave 1 0 0 setrgbcolor fill grestore 2 setlinewidth stroke
    PS

    paths = Postsvg.to_svg(ps).scan(/<path\b[^>]*>/)

    expect(paths.length).to eq(2)
    expect(paths).to all(include(%(d="M 0 0 L 10 0 L 10 10 Z")))
    expect(paths.first).to include(%(fill="#ff0000"))
    expect(paths.last).to include(%(stroke="#000000"), %(stroke-width="2"))
  end
end
