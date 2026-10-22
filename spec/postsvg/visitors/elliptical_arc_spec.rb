# frozen_string_literal: true

require "postsvg"

RSpec.describe Postsvg::Visitors::PsVisitor do # rubocop:disable RSpec/SpecFilePathFormat
  it "consumes temporary arc operands and restores the saved CTM without discarding the path" do
    visitor = described_class.new(builder: Postsvg::SvgBuilder.new)
    visitor.visit_program(Postscript::Source.parse("40 0 moveto"))
    original_stack = visitor.stack.dup
    visitor.visit_program(Postscript::Source.parse(
                            "matrix currentmatrix [1 0 0 1 0 0] concat 40 30 scale " \
                            "0 0 1 0 90 arc setmatrix",
                          ))

    expect(visitor.graphics.current.ctm).to be_identity
    expect(visitor.stack).to eq(original_stack)
    expect(visitor.path.to_path_d).to eq("M 40 0 A 40 30 0 0 1 0 30")
  end
end
