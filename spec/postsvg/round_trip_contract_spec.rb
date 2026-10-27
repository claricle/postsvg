# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe "model-level round-trip contract" do # rubocop:disable RSpec/DescribeClass
  let(:root) { File.expand_path("../fixtures/round_trip", __dir__) }

  manifest_root = File.expand_path("../fixtures/round_trip", __dir__)
  entries = YAML.safe_load_file(File.join(manifest_root, "manifest.yml")).fetch("fixtures")

  before(:example, :native) do
    reason = RoundTrip::NativeParser.unavailability_reason
    skip("native round-trip unavailable: #{reason}") if reason
  end

  def pending_marker(marker)
    expect(marker.keys - %w[known_gap non_goal]).to be_empty
    expect(marker.size).to be <= 1
    return if marker.empty?

    reason = marker.fetch("known_gap") { marker.fetch("non_goal") }
    expect(reason).to be_a(String).and(satisfy { |value| !value.empty? })
    pending(reason)
  end

  def gradient_paint(svg)
    root = Leptris::XML.parse(svg, options: Leptris::XML::ParseOptions.noblanks).root
    gradients = root.xpath(".//*[local-name()='linearGradient' or local-name()='radialGradient']")
    fills = root.xpath(".//*[@fill]").map { |node| node["fill"] }.select { |fill| fill.start_with?("url(") }
    [gradients.map(&:to_s), fills]
  end

  it "rejects misspelled markers before making an example pending", :round_trip do
    expect { pending_marker("know_gap" => "misspelled") }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError, /know_gap/)
  end

  entries.each do |entry|
    it entry.fetch("file"), :round_trip do
      pending_marker(entry.fetch("model", {}))

      svg = File.read(File.join(root, entry.fetch("file")))
      diff = RoundTrip::Harness.call(svg)

      expect(diff).to be_empty, -> { "round-trip diff:\n#{diff.inspect}" }
    end

    it "native parser parity for #{entry.fetch('file')}", :native, :round_trip do
      pending_marker(entry.fetch("model", {}))

      svg = File.read(File.join(root, entry.fetch("file")))
      native_parser = lambda do |source|
        native = RoundTrip::NativeParser.call(source)
        ruby = Postscript::Source.parse(source)
        expect(RoundTrip::Normalizer.call(native)).to eq(RoundTrip::Normalizer.call(ruby))
        native
      end
      diff = RoundTrip::Harness.call(svg, parser: native_parser)

      expect(diff).to be_empty, -> { "native round-trip diff:\n#{diff.inspect}" }
    end

    next unless entry.fetch("family") == "gradient"

    # Gradient flattening happens before the model comparison starts. Keep
    # that comparison strict and expose the loss on its actual (SVG) leg.
    it "preserves SVG gradient paint for #{entry.fetch('file')}", :round_trip do
      svg = File.read(File.join(root, entry.fetch("file")))
      expected = gradient_paint(svg)
      expect(expected.first).not_to be_empty
      expect(expected.last).not_to be_empty

      pending_marker(entry.fetch("svg", {}))
      actual = gradient_paint(Postsvg.to_svg(Postsvg.to_ps(svg)))

      expect(actual).to eq(expected)
    end
  end
end
