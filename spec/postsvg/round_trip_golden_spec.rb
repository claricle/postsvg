# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe "round-trip emitted PostScript goldens" do # rubocop:disable RSpec/DescribeClass
  let(:root) { File.expand_path("../fixtures/round_trip", __dir__) }
  # The header names the emitting version, so a version bump would
  # otherwise invalidate every golden. Compare it separately.
  let(:version_line) { /^(%%Title: Translated by Postsvg ).*$/ }

  manifest_root = File.expand_path("../fixtures/round_trip", __dir__)
  entries = YAML.safe_load_file(File.join(manifest_root, "manifest.yml")).fetch("fixtures")

  entries.each do |entry|
    it entry.fetch("file"), :round_trip do
      svg_path = File.join(root, entry.fetch("file"))
      golden_path = svg_path.sub(/\.svg\z/, ".ps.golden")

      expected = File.binread(golden_path)
      actual = Postsvg.to_ps(File.read(svg_path)).b

      expect(actual.sub(version_line, '\\1X'))
        .to eq(expected.sub(version_line, '\\1X'))
      expect(actual[version_line]).to eq(
        "%%Title: Translated by Postsvg #{Postsvg::VERSION}",
      )
    end
  end
end
