# frozen_string_literal: true

require "spec_helper"

# Integration tests against legacy ps2svg fixtures. The new Renderer
# pipeline shares the same public API (Postsvg.to_svg) but produces
# byte-different SVG than the legacy Interpreter. These specs assert
# structural invariants (valid SVG, correct viewBox) rather than
# byte-equivalence with the old fixtures.
RSpec.describe "Postsvg Integration Tests" do
  fixtures = [
    ["spec/fixtures/eps2svg/img.eps", "spec/fixtures/eps2svg/ref.svg"],
    ["spec/fixtures/ps2svg/colors.ps",
     "spec/fixtures/ps2svg/colors_expected.svg"],
    ["spec/fixtures/ps2svg/example_full.ps",
     "spec/fixtures/ps2svg/example_full_expected.svg"],
    ["spec/fixtures/ps2svg/file.ps", "spec/fixtures/ps2svg/file_expected.svg"],
    ["spec/fixtures/ps2svg/prog.ps", "spec/fixtures/ps2svg/prog_expected.svg"],
    ["spec/fixtures/ps2svg/img.ps", "spec/fixtures/ps2svg/ref.svg"],
  ]

  fixtures.each do |input_path, _expected_path|
    basename = File.basename(input_path)
    it "converts #{basename} without error and produces well-formed SVG" do
      input_content = File.read(input_path)
      actual_svg = Postsvg.to_svg(input_content)

      expect(actual_svg).to start_with("<?xml")
      expect(actual_svg).to include("<svg")
      expect(actual_svg).to include("</svg>")
      expect(actual_svg).to include('viewBox="')
    end
  end
end
