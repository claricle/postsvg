# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Postsvg do
  it "has a version number" do
    expect(Postsvg::VERSION).not_to be_nil
  end

  describe ".convert" do
    it "converts PostScript content to SVG" do
      ps_content = <<~PS
        %!PS-Adobe-3.0 EPSF-3.0
        %%BoundingBox: 0 0 100 100
        newpath
        10 10 moveto
        90 10 lineto
        90 90 lineto
        10 90 lineto
        closepath
        stroke
      PS

      svg_output = described_class.convert(ps_content)

      expect(svg_output).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(svg_output).to include("<svg")
      expect(svg_output).to match(/viewBox="0(.0)? 0(.0)? 100(.0)? 100(.0)?"/)
      expect(svg_output).to include("</svg>")
      # NOTE: Path generation depends on proper parsing - tested separately
    end
  end

  describe ".convert_file" do
    let(:input_path) { fixture_path("ps2svg/colors.ps") }
    let(:output_path) { File.join(Dir.tmpdir, "test_output.svg") }

    after do
      FileUtils.rm_f(output_path)
    end

    it "converts a PostScript file to SVG" do
      svg_output = described_class.convert_file(input_path, output_path)

      expect(File.exist?(output_path)).to be true
      expect(svg_output).to include("<svg")
      expect(svg_output).to include("</svg>")
    end

    it "returns SVG content without writing to file when output_path is nil" do
      svg_output = described_class.convert_file(input_path)

      expect(svg_output).to include("<svg")
      expect(svg_output).to include("</svg>")
    end
  end
end
