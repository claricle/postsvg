# frozen_string_literal: true

require "spec_helper"

RSpec.describe RoundTrip::Normalizer do
  let(:path) { Postscript::Model::Operators::Path }

  it "unwraps operand literals and rounds floats" do
    operator = path::Moveto.new(
      x: Postscript::Model::Literals::Number.new(1.23456),
      y: 2.34567,
    )

    expect(described_class.call([operator])).to eq(
      [["moveto", { x: 1.235, y: 2.346 }]],
    )
  end

  it "normalizes computed and array operands" do
    font = Postscript::Model::Operators::Font::Setfont.new(
      font: Postscript::Model::Computed.new(operator_keyword: "scalefont"),
    )
    dash = Postscript::Model::Operators::GraphicsState::Setdash.new(
      pattern: Postscript::Model::Literals::ArrayLiteral.new(
        [Postscript::Model::Literals::Number.new(1.2345)],
      ),
      offset: 0,
    )

    expect(described_class.call([font, dash])).to eq(
      [
        ["setfont", { font: :computed }],
        ["setdash", { pattern: [1.235], offset: 0 }],
      ],
    )
  end

  it "makes keyword-only classes and dropped records explicit" do
    keyword_only_classes = [
      Postscript::Model::Operators::GraphicsState::Gsave,
      Postscript::Model::Operators::Path::Newpath,
      Postscript::Model::Operators::Path::Closepath,
      Postscript::Model::Operators::Painting::Fill,
      Postscript::Model::Operators::GraphicsState::Grestore,
    ]
    literal = Postscript::Model::Literals::Number.new(12)
    showpage = Postscript::Model::Operators::Device::Showpage.new
    records = keyword_only_classes.map(&:new).insert(2, literal).push(showpage)

    expect(described_class.call(records)).to eq(
      keyword_only_classes.map { |klass| [klass.new.keyword, {}] },
    )
  end

  describe RoundTrip::Harness do
    let(:shape_svg) do
      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
          <rect x="10" y="10" width="30" height="20" fill="#808080"/>
          <circle cx="70" cy="50" r="10" fill="#336699"/>
        </svg>
      SVG
    end

    let(:text_svg) do
      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
          <text x="10" y="20" font-family="Helvetica" font-size="12">Hello</text>
        </svg>
      SVG
    end

    let(:numeric_findfont_parser) do
      lambda do |source|
        program = Postscript::Source.parse(source)
        body = program.body.map { |record| numeric_findfont(record) }
        program.with(body: body)
      end
    end

    def numeric_findfont(record)
      return record unless record.is_a?(Postscript::Model::Operators::Font::Findfont)

      Postscript::Model::Operators::Font::Findfont.new(
        name: Postscript::Model::Literals::Number.new(7),
      )
    end

    it "finds no differences after round-tripping a rect and circle" do
      expect(described_class.call(shape_svg)).to be_empty
    end

    it "reports operand differences for text operators" do
      differences = described_class.call(text_svg, parser: numeric_findfont_parser)
      findfont_difference = differences.find do |difference|
        difference[:expected].first == "findfont"
      end

      expect(findfont_difference).to eq(
        index: 1,
        expected: ["findfont", { name: "Helvetica" }],
        actual: ["findfont", { name: 7 }],
      )
    end
  end
end
