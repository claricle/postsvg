# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Svg::Element subclasses" do
  before(:all) { Postsvg::Svg::Elements.load_all! }

  def parse_one(svg)
    Postsvg::Svg::Parser.call("<svg xmlns=\"http://www.w3.org/2000/svg\">#{svg}</svg>").root_element.children.first
  end

  it "Rect exposes typed x/y/width/height" do
    rect = parse_one(%(<rect x="10" y="20" width="80" height="60" fill="#abc"/>))
    expect(rect).to be_a(Postsvg::Svg::Elements::Rect)
    expect(rect.x).to eq(10.0)
    expect(rect.width).to eq(80.0)
    expect(rect.fill.value).to eq(Postscript::Color.parse("#aabbcc"))
  end

  it "Circle exposes cx/cy/r" do
    circle = parse_one(%(<circle cx="50" cy="50" r="40"/>))
    expect(circle.cx).to eq(50.0)
    expect(circle.r).to eq(40.0)
  end

  it "Ellipse exposes cx/cy/rx/ry" do
    ellipse = parse_one(%(<ellipse cx="100" cy="100" rx="80" ry="60"/>))
    expect([ellipse.rx, ellipse.ry]).to eq([80.0, 60.0])
  end

  it "Line exposes x1/y1/x2/y2" do
    line = parse_one(%(<line x1="10" y1="20" x2="30" y2="40"/>))
    expect([line.x1, line.y1, line.x2, line.y2]).to eq([10.0, 20.0, 30.0, 40.0])
  end

  it "Polygon has same interface as Polyline (points list)" do
    polygon = parse_one(%(<polygon points="10,10 20,20 30,10"/>))
    expect(polygon.points).to eq([10.0, 10.0, 20.0, 20.0, 30.0, 10.0])
  end

  it "Text captures content and font" do
    text = parse_one(%(<text x="5" y="10" font-family="Helvetica" font-size="12">Hi</text>))
    expect(text.content).to eq("Hi")
    expect(text.font_family).to eq("Helvetica")
    expect(text.font_size).to eq(12.0)
  end

  it "Image captures href" do
    image = parse_one(%(<image x="0" y="0" width="100" height="100" href="data:image/png;base64,xxx"/>))
    expect(image.href).to start_with("data:image")
  end

  it "Group captures children" do
    group = parse_one(%(<g><rect width="5" height="5"/><circle r="3"/></g>))
    expect(group.children.length).to eq(2)
  end

  it "Every element exposes base getters (children, transform, fill, stroke_paint, stroke)" do
    rect = parse_one(%(<rect width="5" height="5"/>))
    expect(rect.children).to eq([])
    expect(rect.transform&.empty?).to be(true)
    expect(rect.fill.none?).to be(true) # no fill attribute → Paint(:none)
    expect(rect.stroke_paint.none?).to be(true)
    expect(rect.stroke).to be_a(Postsvg::Svg::Stroke) # always parsed (default values)
  end
end
