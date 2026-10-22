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
      [["moveto", { x: 1.2346, y: 2.3457 }]],
    )
  end

  it "rounds to the serializer's 4 decimals, so its rounding is not a difference" do
    color = Postscript::Model::Operators::Color::Setrgbcolor
    written = color.new(red: 0.094, green: 0.192, blue: 0.32549)
    parsed = color.new(red: 0.094, green: 0.192, blue: 0.3255)

    expect(described_class.call([written])).to eq(described_class.call([parsed]))
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
        ["setdash", { pattern: [1.2345], offset: 0 }],
      ],
    )
  end

  describe "keyword-only coverage gaps" do
    # Pin the full registry remainder, including operand-bearing operators.
    # New classes or changes to ATTRIBUTE_READERS must update this inventory.
    let(:known_gaps) do
      {
        Arithmetic: %w[Abs Add Atan Ceiling Cos Div Exp Floor Idiv Ln Log Mod
                       Mul Neg Round Sin Sqrt Sub Truncate],
        Boolean: %w[And Bitshift Eq False Ge Gt Le Lt Ne Not Or True Xor],
        Container: %w[Anchorsearch Astore Cvs Forall Get Getinterval Length Put
                      Putinterval Search String Token],
        ControlFlow: %w[Exec Exit For If Ifelse Loop Quit Repeat Stopped],
        Device: %w[Copypage Nulldevice Showpage],
        Dictionary: %w[Begin Countdictstack Currentdict Def Dict Dictstack End
                       Known Load Maxlength Store],
        GraphicsState: %w[Grestore Grestoreall Gsave],
        Painting: %w[Clip Eoclip Eofill Fill Stroke],
        Path: %w[Closepath Currentpoint Newpath],
        Stack: %w[Clear Count Dup Exch Index Pop Roll],
        Transformations: %w[Currentmatrix Dtransform Idtransform Itransform
                            Matrix Transform],
      }.flat_map do |category, names|
        names.map { |name| "Postscript::Model::Operators::#{category}::#{name}" }
      end
    end

    it "lists every registered class missing from the attribute table" do
      registry = Postscript::Model::Operators
      registry.load_all!
      registered_classes = registry.keywords.map { |keyword| registry[keyword] }.uniq
      missing_classes = registered_classes - described_class::ATTRIBUTE_READERS.keys

      expect(missing_classes.map(&:name)).to match_array(known_gaps)
    end

    it "falls back to keywords for unmapped path, transform and graphics state classes" do
      records = [
        Postscript::Model::Operators::Path::Currentpoint.new,
        Postscript::Model::Operators::Transformations::Transform.new,
        Postscript::Model::Operators::GraphicsState::Grestoreall.new,
      ]

      expect(described_class.call(records)).to eq(
        [["currentpoint", {}], ["transform", {}], ["grestoreall", {}]],
      )
    end
  end

  it "drops spliced literals and the trailing showpage" do
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

    it "finds no differences after round-tripping a rect and circle" do
      expect(described_class.call(shape_svg)).to be_empty
    end

    it "finds no differences after round-tripping text operands" do
      expect(described_class.call(text_svg)).to be_empty
    end

    it "reports text operands changed by the parser" do
      parser = lambda do |source|
        Postscript::Source.parse(source.sub("(Hello)", "(Changed)"))
      end

      expect(described_class.call(text_svg, parser: parser)).to eq(
        [
          { index: 5, expected: ["show", { text: "Hello" }],
            actual: ["show", { text: "Changed" }] },
        ],
      )
    end
  end
end
