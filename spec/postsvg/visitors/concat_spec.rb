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

  it "applies an array-literal matrix to setmatrix" do
    svg = Postsvg.to_svg(
      "[1 0 0 1 5 5] setmatrix newpath 0 0 moveto 5 5 lineto stroke",
    )

    expect(svg).to include(%(transform="translate(5 5)"))
  end

  # A named matrix used to raise TypeError. Name lookup does not push
  # dictionary values yet, so a named matrix is not applied, and nothing
  # left on the runtime stack by def is mistaken for it.
  it "does not apply a value def left on the stack" do
    svg = Postsvg.to_svg(
      "/m [1 0 0 1 5 5] def /n [1 0 0 1 7 7] def m concat " \
      "newpath 0 0 moveto 5 5 lineto stroke",
    )

    expect(svg).not_to include("translate(7 7)")
    expect(svg).not_to include("translate(5 5)")
  end

  it "applies an array-literal matrix only once" do
    svg = Postsvg.to_svg(
      "[1 0 0 1 5 5] concat foo concat newpath 0 0 moveto 5 5 lineto stroke",
    )

    expect(svg).to include(%(transform="translate(5 5)"))
    expect(svg).not_to include("translate(10 10)")
  end

  it "restores a saved matrix with setmatrix" do
    svg = Postsvg.to_svg(
      "matrix currentmatrix [1 0 0 1 5 5] concat setmatrix " \
      "newpath 0 0 moveto 5 5 lineto stroke",
    )

    expect(svg).not_to include("translate(5 5)")
    expect(svg).to include("M 0 0 L 5 5")
  end

  it "ignores an array that is not six numbers" do
    expect do
      Postsvg.to_svg("[1 0 0 1 5] concat newpath 0 0 moveto 5 5 lineto stroke")
    end.not_to raise_error
  end
end
