# frozen_string_literal: true

require "postsvg"

RSpec.describe Postsvg::Translation::HandlerRegistry do
  let(:base_element) { Class.new(Postsvg::Svg::Element) }
  let(:child_element) { Class.new(base_element) }
  let(:handler) { Class.new { def self.call(*_args); end } }

  it "looks up handler by exact class" do
    registry = described_class.new
    registry.register(base_element, handler)
    elem = base_element.new
    expect(registry.handler_for(elem)).to eq(handler)
  end

  it "walks superclass chain when no direct match" do
    registry = described_class.new
    registry.register(base_element, handler)
    child = child_element.new
    expect(registry.handler_for(child)).to eq(handler)
  end

  it "returns nil when no handler matches" do
    registry = described_class.new
    expect(registry.handler_for(base_element.new)).to be_nil
  end
end

RSpec.describe Postsvg::Translation::PsRenderer do
  before(:all) { described_class.register_default_handlers! }

  it "translates a rect SVG to a PS program with moveto/rlineto/closepath/fill" do
    svg = %{<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect x="10" y="10" width="80" height="80" fill="#808080"/></svg>}
    document = Postsvg::Svg::Parser.call(svg)
    program = described_class.call(document)
    classes = program.body.map(&:class)
    expect(classes).to include(Postscript::Model::Operators::Path::Moveto)
    expect(classes).to include(Postscript::Model::Operators::Path::Rlineto)
    expect(classes).to include(Postscript::Model::Operators::Path::Closepath)
    expect(classes).to include(Postscript::Model::Operators::Painting::Fill)
  end

  it "captures the SVG viewbox in the program header bounding_box" do
    svg = %{<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 100"><rect width="50" height="50"/></svg>}
    program = described_class.call(Postsvg::Svg::Parser.call(svg))
    expect(program.header.bounding_box).to eq([0.0, 0.0, 200.0, 100.0])
  end
end
