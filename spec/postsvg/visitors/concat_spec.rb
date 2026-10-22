# frozen_string_literal: true

require "postsvg"

# The task card pins this regression coverage to concat_spec.rb.
RSpec.describe Postsvg::Visitors::PsVisitor do # rubocop:disable RSpec/SpecFilePathFormat
  it "applies an array-literal matrix" do
    svg = Postsvg.to_svg(
      "[1 0 0 1 5 5] concat newpath 0 0 moveto 5 5 lineto stroke",
    )

    expect(svg).to include(%(transform="translate(5 5)"))
    expect(svg).to include("M 0 0 L 5 5")
  end

  it "applies a computed matrix from the runtime stack" do
    svg = Postsvg.to_svg(
      "5 5 translate matrix currentmatrix concat " \
      "newpath 0 0 moveto 5 5 lineto stroke",
    )

    expect(svg).to include(%(transform="translate(10 10)"))
    expect(svg).to include("M 0 0 L 5 5")
  end
end
