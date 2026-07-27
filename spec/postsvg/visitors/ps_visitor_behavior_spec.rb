# frozen_string_literal: true

require "spec_helper"

RSpec.describe "PsVisitor arithmetic behavior" do
  def evaluate(ps_body)
    program = Postsvg::Source.parse("%!PS-Adobe-3.0\n%%BoundingBox: 0 0 100 100\n#{ps_body}\nshowpage\n")
    builder = Postsvg::SvgBuilder.new
    visitor = Postsvg::Visitors::PsVisitor.new(builder: builder)
    visitor.visit_program(program)
    visitor
  end

  it "add computes a + b" do
    expect(evaluate("3 4 add").stack.last).to eq(7)
  end

  it "sub computes a - b" do
    expect(evaluate("10 3 sub").stack.last).to eq(7)
  end

  it "mul computes a * b" do
    expect(evaluate("6 7 mul").stack.last).to eq(42)
  end

  it "div computes a / b" do
    expect(evaluate("10 4 div").stack.last).to eq(2.5)
  end

  it "idiv truncates to integer" do
    expect(evaluate("10 3 idiv").stack.last).to eq(3)
  end

  it "mod returns the remainder" do
    expect(evaluate("10 3 mod").stack.last).to eq(1)
  end

  it "neg flips sign" do
    expect(evaluate("5 neg").stack.last).to eq(-5)
  end

  it "abs returns absolute value" do
    expect(evaluate("-5 abs").stack.last).to eq(5)
  end

  it "sqrt returns the square root" do
    expect(evaluate("16 sqrt").stack.last).to eq(4.0)
  end

  it "div by zero raises RenderError" do
    expect { evaluate("10 0 div") }.to raise_error(Postsvg::RenderError)
  end

  it "chained ops: 1 2 add 3 mul = 9" do
    expect(evaluate("1 2 add 3 mul").stack.last).to eq(9)
  end
end

RSpec.describe "PsVisitor boolean behavior" do
  def evaluate(ps_body)
    program = Postsvg::Source.parse("%!PS-Adobe-3.0\n%%BoundingBox: 0 0 100 100\n#{ps_body}\n")
    visitor = Postsvg::Visitors::PsVisitor.new(builder: Postsvg::SvgBuilder.new)
    visitor.visit_program(program)
    visitor
  end

  it "eq pushes true for equal numbers" do
    expect(evaluate("3 3 eq").stack.last).to be true
    expect(evaluate("3 4 eq").stack.last).to be false
  end

  it "gt / lt / ge / le compare numerically" do
    expect(evaluate("5 3 gt").stack.last).to be true
    expect(evaluate("3 5 lt").stack.last).to be true
    expect(evaluate("5 5 ge").stack.last).to be true
    expect(evaluate("5 5 le").stack.last).to be true
    expect(evaluate("3 5 ge").stack.last).to be false
  end
end

RSpec.describe "PsVisitor control flow behavior" do
  def evaluate(ps_body)
    program = Postsvg::Source.parse("%!PS-Adobe-3.0\n%%BoundingBox: 0 0 100 100\n#{ps_body}\n")
    visitor = Postsvg::Visitors::PsVisitor.new(builder: Postsvg::SvgBuilder.new)
    visitor.visit_program(program)
    visitor
  end

  # PS +if+ consumes the condition. To verify the body runs, leave
  # something distinct on the stack from inside the body.
  it "if executes body when condition is truthy" do
    v = evaluate("true { 42 } if")
    expect(v.stack.last).to eq(42)
  end

  it "if does not execute body when condition is false" do
    v = evaluate("false { 42 } if")
    expect(v.stack).to be_empty
  end

  it "ifelse takes the correct branch" do
    expect(evaluate("true { 1 } { 2 } ifelse").stack.last).to eq(1)
    expect(evaluate("false { 1 } { 2 } ifelse").stack.last).to eq(2)
  end

  it "repeat runs body N times" do
    v = evaluate("0 5 { 1 add } repeat")
    expect(v.stack.last).to eq(5)
  end

  it "for pushes the loop counter" do
    v = evaluate("1 1 3 { } for")
    # Loop pushed 1, 2, 3 in order.
    expect(v.stack.last(3)).to eq([1.0, 2.0, 3.0])
  end
end

RSpec.describe "PsVisitor dictionary behavior" do
  def evaluate(ps_body)
    program = Postsvg::Source.parse("%!PS-Adobe-3.0\n%%BoundingBox: 0 0 100 100\n#{ps_body}\n")
    visitor = Postsvg::Visitors::PsVisitor.new(builder: Postsvg::SvgBuilder.new)
    visitor.visit_program(program)
    visitor
  end

  it "def and load round-trip a value" do
    v = evaluate("/foo 42 def /foo load")
    # Stored value is a Number wrapper; visitor pushes it as-is.
    expect(v.stack.last).to be_a(Postsvg::Model::Literals::Number)
    expect(v.stack.last.value).to eq(42)
  end

  it "currentdict returns the active dict" do
    v = evaluate("/x 5 def currentdict")
    expect(v.stack.last).to be_a(Hash)
    expect(v.stack.last.key?("x")).to be true
  end

  it "countdictstack reflects nested begins" do
    v = evaluate("/a 1 def 1 dict begin /b 2 def countdictstack")
    expect(v.stack.last).to eq(2)
  end
end

RSpec.describe "PsVisitor container behavior" do
  def evaluate(ps_body)
    program = Postsvg::Source.parse("%!PS-Adobe-3.0\n%%BoundingBox: 0 0 100 100\n#{ps_body}\n")
    visitor = Postsvg::Visitors::PsVisitor.new(builder: Postsvg::SvgBuilder.new)
    visitor.visit_program(program)
    visitor
  end

  it "length works on strings and arrays" do
    expect(evaluate("(hello) length").stack.last).to eq(5)
    expect(evaluate("[1 2 3] length").stack.last).to eq(3)
  end

  it "search returns true on match" do
    v = evaluate("(hello world) (world) search")
    expect(v.stack.last).to be true
  end

  it "string creates a zero-filled buffer" do
    v = evaluate("5 string")
    expect(v.stack.last.length).to eq(5)
  end
end

RSpec.describe "PsVisitor font behavior" do
  def evaluate(ps_body)
    program = Postsvg::Source.parse("%!PS-Adobe-3.0\n%%BoundingBox: 0 0 100 100\n#{ps_body}\n")
    visitor = Postsvg::Visitors::PsVisitor.new(builder: Postsvg::SvgBuilder.new)
    visitor.visit_program(program)
    visitor
  end

  it "findfont + scalefont + setfont updates graphics state" do
    v = evaluate("/Helvetica findfont 18 scalefont setfont")
    expect(v.graphics.current.font_name).to eq("Helvetica")
    expect(v.graphics.current.font_size).to eq(18.0)
  end
end
