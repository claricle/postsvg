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

  # A named matrix used to raise TypeError: the runtime stack holds parsed
  # Number literals, not plain numbers. (Name lookup itself does not push
  # dictionary values yet, so this only checks that nothing raises.)
  it "does not raise on a matrix stored under a name" do
    expect do
      Postsvg.to_svg("/m [1 0 0 1 5 5] def m concat newpath 0 0 moveto 5 5 lineto stroke")
    end.not_to raise_error
  end

  it "applies a parsed array that reaches concat through the stack" do
    svg = Postsvg.to_svg(
      "[1 0 0 1 5 5] dup pop concat newpath 0 0 moveto 5 5 lineto stroke",
    )

    expect(svg).to include(%(transform="translate(5 5)"))
  end

  it "applies a parsed array that reaches setmatrix through the stack" do
    svg = Postsvg.to_svg(
      "[1 0 0 1 5 5] dup pop setmatrix newpath 0 0 moveto 5 5 lineto stroke",
    )

    expect(svg).to include(%(transform="translate(5 5)"))
  end

  it "ignores an array that is not six numbers" do
    expect do
      Postsvg.to_svg("[1 0 0 1 5] concat newpath 0 0 moveto 5 5 lineto stroke")
    end.not_to raise_error
  end
end
