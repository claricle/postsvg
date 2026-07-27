# frozen_string_literal: true

require "postsvg"

RSpec.describe Postsvg::Source::AstBuilder do
  def parse(src)
    Postsvg::Source.parse(src)
  end

  it "captures BoundingBox in header" do
    program = parse("%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 0 0 100 100\nshowpage\n")
    expect(program.header.bounding_box).to eq([0.0, 0.0, 100.0, 100.0])
  end

  it "captures HiResBoundingBox when present" do
    program = parse("%%HiResBoundingBox: 0.0 0.0 99.5 99.5\n")
    expect(program.header.hires_bounding_box).to eq([0.0, 0.0, 99.5, 99.5])
  end

  it "builds Moveto from operands" do
    program = parse("10 20 moveto\n")
    op = program.body.last
    expect(op).to be_a(Postsvg::Model::Operators::Path::Moveto)
    expect(op.x).to eq(10)
    expect(op.y).to eq(20)
  end

  it "builds Setrgbcolor from operands" do
    program = parse("1 0 0 setrgbcolor\n")
    op = program.body.last
    expect(op.red).to eq(1)
    expect(op.green).to eq(0)
    expect(op.blue).to eq(0)
  end

  it "captures Procedure as a literal node" do
    program = parse("{ 10 20 moveto }\n")
    proc = program.body.first
    expect(proc).to be_a(Postsvg::Model::Literals::Procedure)
    # Procedure body has Number, Number, Moveto in source order.
    expect(proc.body.length).to eq(3)
    expect(proc.body.last).to be_a(Postsvg::Model::Operators::Path::Moveto)
  end

  it "captures InvokeProcedure when def'd name is invoked" do
    program = parse("/foo { 10 10 moveto } def\nfoo\n")
    inv = program.body.last
    expect(inv).to be_a(Postsvg::Model::InvokeProcedure)
    expect(inv.name).to eq("foo")
  end

  it "preserves unknown operators" do
    program = parse("nonsense_operator\n")
    op = program.body.first
    expect(op).to be_a(Postsvg::Model::UnknownOperator)
    expect(op.keyword).to eq("nonsense_operator")
  end
end
