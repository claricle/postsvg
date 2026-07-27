# frozen_string_literal: true

require "postsvg"

RSpec.describe Postsvg::Serializer do
  def serialize(program, **opts)
    Postsvg::Serializer.call(program, **opts)
  end

  it "emits a header with EPSF-3.0 marker when eps: true" do
    program = Postsvg::Model::Program.new(
      header: Postsvg::Model::Program::Header.new(bounding_box: [0, 0, 100, 100], epsf: true),
      body: [],
    )
    out = serialize(program, eps: true)
    expect(out).to include("%!PS-Adobe-3.0 EPSF-3.0")
    expect(out).to include("%%BoundingBox: 0 0 100 100")
    expect(out).to include("%%EndComments")
    expect(out).to include("showpage")
    expect(out).to include("%%EOF")
  end

  it "emits moveto with operands" do
    program = Postsvg::Model::Program.new(
      body: [Postsvg::Model::Operators::Path::Moveto.new(x: 10, y: 20)],
    )
    expect(serialize(program)).to include("10 20 moveto")
  end

  it "emits setrgbcolor with three floats" do
    program = Postsvg::Model::Program.new(
      body: [Postsvg::Model::Operators::Color::Setrgbcolor.new(red: 1, green: 0.5, blue: 0)],
    )
    expect(serialize(program)).to include("1 0.5 0 setrgbcolor")
  end

  it "emits arc with operands" do
    op = Postsvg::Model::Operators::Path::Arc.new(x: 0, y: 0, radius: 10, angle1: 0, angle2: 360)
    program = Postsvg::Model::Program.new(body: [op])
    expect(serialize(program)).to include("0 0 10 0 360 arc")
  end
end
