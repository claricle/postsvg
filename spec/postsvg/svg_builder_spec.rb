# frozen_string_literal: true

require "postsvg"

RSpec.describe Postsvg::SvgBuilder do
  def builder
    Postsvg::SvgBuilder.new
  end

  it "emits a well-formed SVG document" do
    b = builder
    b.open_svg(viewbox: "0 0 100 100", width: 100, height: 100)
    b.path(d: "M 0 0 L 100 100", mode: :stroke, color: Postscript::Color::BLACK)
    b.close_svg
    output = b.to_s
    expect(output).to include('<?xml version="1.0"')
    expect(output).to include("<svg")
    expect(output).to include("</svg>")
  end

  it "deduplicates clip paths" do
    b = builder
    b.open_svg(viewbox: "0 0 100 100", width: 100, height: 100)
    id1 = b.register_clip_path("M 0 0 L 10 10")
    id2 = b.register_clip_path("M 0 0 L 10 10")
    id3 = b.register_clip_path("M 0 0 L 99 99")
    expect(id1).to eq(id2)
    expect(id3).not_to eq(id1)
    b.close_svg
    expect(b.registered_clip_count).to eq(2)
  end

  it "raises if svg not closed before to_s" do
    b = builder
    b.open_svg(viewbox: "0 0 1 1", width: 1, height: 1)
    expect { b.to_s }.to raise_error(Postsvg::RenderError)
  end

  it "escapes XML special chars in text content" do
    b = builder
    b.open_svg(viewbox: "0 0 1 1", width: 1, height: 1)
    b.text(content: "<bad> & stuff", x: 0, y: 0,
           font_family: "Helvetica", font_size: 12,
           color: Postscript::Color::BLACK)
    b.close_svg
    expect(b.to_s).to include("&lt;bad&gt;")
    expect(b.to_s).to include("&amp; stuff")
  end
end
