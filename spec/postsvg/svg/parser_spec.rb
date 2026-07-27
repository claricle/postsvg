# frozen_string_literal: true

require "postsvg"

RSpec.describe Postsvg::Svg::Parser do
  def parse(svg)
    Postsvg::Svg::Parser.call(svg)
  end

  it "parses a rect into typed Rect" do
    doc = parse(%{<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect x="10" y="10" width="80" height="80" fill="#abc"/></svg>})
    rect = doc.root_element.children.first
    expect(rect).to be_a(Postsvg::Svg::Elements::Rect)
    expect(rect.x).to eq(10.0)
    expect(rect.y).to eq(10.0)
    expect(rect.width).to eq(80.0)
    expect(rect.height).to eq(80.0)
    expect(rect.fill).to be_color
    expect(rect.fill.value).to eq(Postsvg::Color.parse("#aabbcc"))
  end

  it "parses a circle with float radius" do
    doc = parse(%{<svg xmlns="http://www.w3.org/2000/svg"><circle cx="50" cy="50" r="25.5"/></svg>})
    circle = doc.root_element.children.first
    expect(circle.r).to eq(25.5)
  end

  it "parses a group with transform" do
    doc = parse(%{<svg xmlns="http://www.w3.org/2000/svg"><g transform="translate(10 20)"><rect width="5" height="5"/></g></svg>})
    group = doc.root_element.children.first
    expect(group).to be_a(Postsvg::Svg::Elements::Group)
    expect(group.transform).not_to be_nil
    expect(group.transform.matrices.length).to eq(1)
  end

  it "extracts viewBox from root" do
    doc = parse(%{<svg xmlns="http://www.w3.org/2000/svg" viewBox="10 20 30 40"></svg>})
    expect(doc.viewbox).to eq([10.0, 20.0, 30.0, 40.0])
  end
end

RSpec.describe Postsvg::Svg::PathData do
  it "parses moveto + lineto + closepath" do
    cmds = Postsvg::Svg::PathData.parse("M 10 10 L 20 20 Z")
    expect(cmds.map(&:opcode)).to eq(%w[M L Z])
    expect(cmds[0].args).to eq([10.0, 10.0])
    expect(cmds[1].args).to eq([20.0, 20.0])
  end

  it "supports implicit lineto after moveto" do
    cmds = Postsvg::Svg::PathData.parse("M 10 10 20 20 30 30")
    expect(cmds.map(&:opcode)).to eq(%w[M L L])
  end
end
