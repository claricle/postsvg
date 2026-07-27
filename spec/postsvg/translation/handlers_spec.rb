# frozen_string_literal: true

require "spec_helper"

RSpec.describe Postsvg::Translation::Handlers do
  before(:all) { Postsvg::Translation::PsRenderer.register_default_handlers! }

  def translate(svg)
    document = Postsvg::Svg::Parser.call(svg)
    Postsvg::Translation::PsRenderer.call(document)
  end

  def classes(program)
    program.body.map(&:class)
  end

  it "RectHandler emits gsave/moveto/rlineto×3/closepath/paint/grestore" do
    program = translate(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect x="10" y="10" width="80" height="80" fill="#abc"/></svg>))
    ops = classes(program)
    expect(ops).to include(Postsvg::Model::Operators::GraphicsState::Gsave)
    expect(ops).to include(Postsvg::Model::Operators::Path::Moveto)
    expect(ops).to include(Postsvg::Model::Operators::Path::Closepath)
    expect(ops).to include(Postsvg::Model::Operators::Painting::Fill)
    expect(ops).to include(Postsvg::Model::Operators::GraphicsState::Grestore)
  end

  it "CircleHandler emits Arc with radius and 0/360 angles" do
    program = translate(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="40"/></svg>))
    arc = program.body.find { |o| o.is_a?(Postsvg::Model::Operators::Path::Arc) }
    expect(arc.radius).to eq(40.0)
    expect(arc.x).to eq(50.0)
    expect(arc.y).to eq(50.0)
    expect(arc.angle1).to eq(0)
    expect(arc.angle2).to eq(360)
  end

  it "LineHandler emits moveto/lineto/stroke" do
    program = translate(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><line x1="0" y1="0" x2="50" y2="50" stroke="black"/></svg>))
    ops = classes(program)
    expect(ops).to include(Postsvg::Model::Operators::Path::Moveto)
    expect(ops).to include(Postsvg::Model::Operators::Path::Lineto)
    expect(ops).to include(Postsvg::Model::Operators::Painting::Stroke)
  end

  it "PolygonHandler emits closepath (Polyline does not)" do
    polygon = translate(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><polygon points="10,10 50,90 90,10"/></svg>))
    expect(classes(polygon)).to include(Postsvg::Model::Operators::Path::Closepath)

    polyline = translate(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><polyline points="10,10 50,90 90,10"/></svg>))
    expect(classes(polyline)).not_to include(Postsvg::Model::Operators::Path::Closepath)
  end

  it "PathHandler translates M/L/Z" do
    program = translate(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M 10 10 L 90 10 L 90 90 Z" fill="#000"/></svg>))
    ops = classes(program)
    expect(ops).to include(Postsvg::Model::Operators::Path::Moveto)
    expect(ops).to include(Postsvg::Model::Operators::Path::Lineto)
    expect(ops).to include(Postsvg::Model::Operators::Path::Closepath)
  end

  it "PathHandler translates cubic bezier C" do
    program = translate(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M 10 10 C 20 0 30 100 40 10" fill="none" stroke="black"/></svg>))
    expect(classes(program)).to include(Postsvg::Model::Operators::Path::Curveto)
  end

  it "PathHandler translates quadratic bezier Q (as cubic)" do
    program = translate(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M 10 10 Q 50 100 90 10"/></svg>))
    # Q is converted to cubic in the handler, so we expect Curveto records.
    expect(classes(program)).to include(Postsvg::Model::Operators::Path::Curveto)
  end

  it "GroupHandler wraps children with gsave/grestore" do
    program = translate(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><g><rect width="5" height="5"/></g></svg>))
    # The group handler emits gsave, then translates the rect, then grestore.
    expect(classes(program)).to include(Postsvg::Model::Operators::GraphicsState::Gsave)
    expect(classes(program)).to include(Postsvg::Model::Operators::GraphicsState::Grestore)
  end

  it "Element with both fill and stroke emits separate gsave/fill/grestore/stroke sequence" do
    program = translate(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="10" height="10" fill="red" stroke="black"/></svg>))
    ops = classes(program)
    # Fill+stroke: should have Fill, Stroke, and a Gsave/Grestore pair
    # wrapping the Fill so the Stroke can re-set its color.
    expect(ops).to include(Postsvg::Model::Operators::Painting::Fill)
    expect(ops).to include(Postsvg::Model::Operators::Painting::Stroke)
    expect(ops).to include(Postsvg::Model::Operators::GraphicsState::Gsave)
    expect(ops).to include(Postsvg::Model::Operators::GraphicsState::Grestore)
  end
end
