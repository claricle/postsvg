# frozen_string_literal: true

require "postsvg"

RSpec.describe Postsvg::Source::Lexer do
  def lex(src)
    Postsvg::Source::Lexer.tokenize(src)
  end

  it "tokenizes numbers and operators" do
    tokens = lex("10 20 moveto")
    expect(tokens.map(&:type)).to eq(%i[number number operator])
    expect(tokens.map(&:value)).to eq(["10", "20", "moveto"])
  end

  it "preserves % characters inside string literals" do
    tokens = lex("(100% off) show")
    expect(tokens[0].type).to eq(:string)
    expect(tokens[0].value).to eq("100% off")
  end

  it "captures DSC comments" do
    tokens = lex("%!PS-Adobe-3.0\n%%BoundingBox: 0 0 100 100\n")
    dsc = tokens.select { |t| t.type == :dsc }
    expect(dsc.length).to eq(1)
    expect(dsc.first.value).to eq("BoundingBox: 0 0 100 100")
  end

  it "skips ordinary line comments" do
    tokens = lex("% this is a comment\n10 20 add")
    expect(tokens.none? { |t| t.type == :dsc }).to be true
    expect(tokens.map(&:type)).to eq(%i[number number operator])
  end

  it "tokenizes name literals (leading slash)" do
    tokens = lex("/foo 5 def")
    expect(tokens[0].type).to eq(:name)
    expect(tokens[0].value).to eq("foo")
    expect(tokens[0].literal).to be true
  end

  it "tokenizes hex strings" do
    tokens = lex("<DEADBEEF>")
    expect(tokens[0].type).to eq(:hexstring)
    expect(tokens[0].value).to eq("DEADBEEF")
  end

  it "tokenizes dict delimiters" do
    tokens = lex("<< /A 1 /B 2 >>")
    types = tokens.map(&:type)
    expect(types.first).to eq(:dict_open)
    expect(types.last).to eq(:dict_close)
  end
end
