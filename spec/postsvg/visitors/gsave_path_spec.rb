# frozen_string_literal: true

require "postsvg"

# rubocop:disable-next RSpec/SpecFilePathFormat
RSpec.describe Postsvg::Visitors::PsVisitor do
  it "copies path commands and the current point independently" do
    path = described_class::PathState.new
    path.move_to(3, 4)
    copy = path.dup

    path.commands.first.replace("M 0 0")
    path.line_to(10, 20)
    copy.line_to_rel(2, 3)

    expect(copy.to_path_d).to eq("M 3 4 l 2 3")
    expect([copy.current_x, copy.current_y]).to eq([5, 7])
    expect(path.to_path_d).to eq("M 0 0 L 10 20")
  end

  it "restores nested path snapshots and their current points" do
    visitor = described_class.new(builder: Postsvg::SvgBuilder.new)
    visitor.path.move_to(3, 4)
    visitor.visit_gsave(nil, nil)
    visitor.path.line_to_rel(2, 3)
    visitor.visit_gsave(nil, nil)
    visitor.path.reset
    visitor.visit_grestore(nil, nil)

    expect(visitor.path.to_path_d).to eq("M 3 4 l 2 3")
    expect([visitor.path.current_x, visitor.path.current_y]).to eq([5, 7])
    visitor.visit_grestore(nil, nil)
    expect(visitor.path.to_path_d).to eq("M 3 4")
    expect([visitor.path.current_x, visitor.path.current_y]).to eq([3, 4])
  end

  it "preserves the path when restoring a supplied graphics stack without a path snapshot" do
    graphics = Postsvg::GraphicsStack.new.gsave
    visitor = described_class.new(builder: Postsvg::SvgBuilder.new, graphics: graphics)
    visitor.path.move_to(3, 4)
    visitor.visit_grestore(nil, nil)
    visitor.path.line_to_rel(2, 3)

    expect(visitor.path.to_path_d).to eq("M 3 4 l 2 3")
    expect(graphics.depth).to eq(1)
  end

  it "restores all visitor snapshots over a supplied graphics stack" do
    graphics = Postsvg::GraphicsStack.new.gsave
    visitor = described_class.new(builder: Postsvg::SvgBuilder.new, graphics: graphics)
    visitor.path.move_to(3, 4)
    visitor.visit_gsave(nil, nil)
    visitor.path.reset
    visitor.visit_grestoreall(nil, nil)
    visitor.path.line_to_rel(2, 3)

    expect(visitor.path.to_path_d).to eq("M 3 4 l 2 3")
    expect(graphics.depth).to eq(1)
  end

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
