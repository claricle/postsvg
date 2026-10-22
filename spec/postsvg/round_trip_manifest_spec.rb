# frozen_string_literal: true

require "postsvg"
require "yaml"

RSpec.describe "round-trip fixture manifest" do # rubocop:disable RSpec/DescribeClass
  let(:root) { File.expand_path("../fixtures/round_trip", __dir__) }
  let(:entries) { YAML.safe_load_file(File.join(root, "manifest.yml"))["fixtures"] }
  let(:files) { Dir.glob("**/*.svg", base: root) }
  let(:markers) { %w[known_gap non_goal] }

  it "has exactly one entry per fixture" do
    expect(entries.map { |entry| entry["file"] }).to match_array(files)
  end

  it "names each entry's family after its directory" do
    entries.each do |entry|
      expect(entry["family"]).to eq(File.dirname(entry["file"]))
    end
  end

  it "uses only known_gap or non_goal markers with a reason" do
    entries.each do |entry|
      entry.slice("model", "svg").each_value do |marker|
        expect(marker.keys).to all(satisfy { |key| markers.include?(key) })
        expect(marker.values).to all(be_a(String).and(satisfy { |reason| !reason.empty? }))
      end
    end
  end

  it "parses every fixture" do
    files.each do |file|
      expect { Postsvg::Svg::Parser.call(File.read(File.join(root, file))) }
        .not_to raise_error, file
    end
  end
end
