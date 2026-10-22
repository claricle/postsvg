# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe "SVG-level round-trip contract" do # rubocop:disable RSpec/DescribeClass
  let(:root) { File.expand_path("../fixtures/round_trip", __dir__) }

  manifest_root = File.expand_path("../fixtures/round_trip", __dir__)
  entries = YAML.safe_load_file(File.join(manifest_root, "manifest.yml")).fetch("fixtures")

  def pending_marker(marker)
    expect(marker.keys - %w[known_gap non_goal]).to be_empty
    expect(marker.size).to be <= 1
    return if marker.empty?

    reason = marker.fetch("known_gap") { marker.fetch("non_goal") }
    expect(reason).to be_a(String).and(satisfy { |value| !value.empty? })
    pending(reason)
  end

  it "rejects misspelled markers before making an example pending", :round_trip do
    expect { pending_marker("know_gap" => "misspelled") }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError, /know_gap/)
  end

  entries.each do |entry|
    it entry.fetch("file"), :round_trip do
      pending_marker(entry.fetch("svg", {}))
      source = File.read(File.join(root, entry.fetch("file")))
      result = Postsvg.to_svg(Postsvg.to_ps(source))

      expect(RoundTrip::SvgSummary.call(result))
        .to eq(RoundTrip::SvgSummary.call(source))
    end
  end
end
