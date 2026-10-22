# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe "model-level round-trip contract" do # rubocop:disable RSpec/DescribeClass
  let(:root) { File.expand_path("../fixtures/round_trip", __dir__) }

  manifest_root = File.expand_path("../fixtures/round_trip", __dir__)
  entries = YAML.safe_load_file(File.join(manifest_root, "manifest.yml")).fetch("fixtures")

  entries.each do |entry|
    it entry.fetch("file"), :round_trip do
      model_marker = entry.fetch("model", {})
      pending(model_marker.values.fetch(0)) unless model_marker.empty?

      svg = File.read(File.join(root, entry.fetch("file")))
      diff = RoundTrip::Harness.call(svg)

      expect(diff).to be_empty, -> { "round-trip diff:\n#{diff.inspect}" }
    end
  end
end
