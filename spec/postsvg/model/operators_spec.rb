# frozen_string_literal: true

require "postsvg"

RSpec.describe Postsvg::Model::Operators do
  before(:all) { described_class.load_all! }

  describe "registry" do
    it "registers moveto, lineto, stroke, etc." do
      %w[moveto lineto curveto closepath stroke fill setrgbcolor setgray
         gsave grestore translate scale rotate].each do |kw|
        expect(described_class[kw]).not_to be_nil
      end
    end

    it "returns nil for unknown keywords" do
      expect(described_class["nonsense_12345"]).to be_nil
    end
  end

  describe Postsvg::Model::Operators::Path::Moveto do
    it "pops y first then x from the stack" do
      stack = Postsvg::Source::OperandStack.new
      stack.push(10) # x
      stack.push(20) # y
      op = described_class.from_operands(stack)
      expect(op.x).to eq(10)
      expect(op.y).to eq(20)
    end
  end

  describe Postsvg::Model::Operators::Path::Curveto do
    it "pops operands in reverse-source order" do
      stack = Postsvg::Source::OperandStack.new
      # x1 y1 x2 y2 x3 y3
      stack.push(1)
      stack.push(2)
      stack.push(3)
      stack.push(4)
      stack.push(5)
      stack.push(6)
      op = described_class.from_operands(stack)
      expect(op.x1).to eq(1)
      expect(op.y1).to eq(2)
      expect(op.x2).to eq(3)
      expect(op.y2).to eq(4)
      expect(op.x3).to eq(5)
      expect(op.y3).to eq(6)
    end
  end

  describe Postsvg::Model::Operators::Color::Setrgbcolor do
    it "pops blue first, then green, then red" do
      stack = Postsvg::Source::OperandStack.new
      stack.push(0.1) # r
      stack.push(0.2) # g
      stack.push(0.3) # b
      op = described_class.from_operands(stack)
      expect(op.red).to eq(0.1)
      expect(op.green).to eq(0.2)
      expect(op.blue).to eq(0.3)
    end
  end

  describe Postsvg::Model::Operators::Arithmetic::Sub do
    it "computes a - b" do
      visitor = Class.new do
        include Postsvg::Visitors::PsVisitor::Arithmetic
        include Postsvg::Visitors::PsVisitor::Common

        attr_reader :stack

        def initialize(stack)
          @stack = stack
        end
      end.new([5, 3])
      # Sanity: the visitor pops operand_b (top) and operand_a (next)
      # from the runtime stack and computes a - b.
      op = described_class.new(operand_a: 5, operand_b: 3)
      visitor.visit_sub(op, nil)
      expect(visitor.stack.last).to eq(2)
    end
  end
end
