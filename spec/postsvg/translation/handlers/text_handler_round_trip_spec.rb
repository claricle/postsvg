# frozen_string_literal: true

require "spec_helper"

RSpec.describe Postsvg::Translation::Handlers::TextHandler do
  ["Times New Roman", "Times (New) Roman", 'Times \\ New Roman', "Helvetica"].each do |family|
    context "with font family #{family.inspect}" do
      let(:svg) do
        <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
            <text x="10" y="20" font-family="#{family}" font-size="14">Hi</text>
          </svg>
        SVG
      end

      it "preserves the model through PostScript serialization and parsing" do
        expect(RoundTrip::Harness.call(svg)).to be_empty
      end

      it "preserves the font family in the rendered SVG" do
        result = Postsvg.to_svg(Postsvg.to_ps(svg))

        expect(result).to include(%(font-family="#{family}"))
        expect(result).not_to include("unhandled operator")
      end
    end
  end
end
