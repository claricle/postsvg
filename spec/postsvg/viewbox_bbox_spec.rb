# frozen_string_literal: true

require "postsvg"

RSpec.describe "viewBox bounding box round trip" do # rubocop:disable RSpec/DescribeClass
  dimension_options = ["", 'width="100" height="100"']
  [
    ["10 20 100 100", "10 20 110 120", 10, 20],
    ["-10 -20 100 100", "-10 -20 90 80", -10, -20],
    ["0 0 100 100", "0 0 100 100", 0, 0],
  ].each do |viewbox, bbox, x, y|
    dimension_options.each do |dimensions|
      context "with viewBox #{viewbox} and dimensions #{dimensions.inspect}" do
        let(:source) do
          <<~SVG
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="#{viewbox}" #{dimensions}>
              <rect x="#{x}" y="#{y}" width="30" height="40"/>
            </svg>
          SVG
        end
        let(:postscript) { Postsvg.to_ps(source) }

        it "writes the origin and opposite corner in the BoundingBox" do
          expect(postscript.lines.map(&:chomp)).to include("%%BoundingBox: #{bbox}")
        end

        it "preserves the viewBox origin and dimensions on the round trip" do
          expect(Postsvg.to_svg(postscript)).to include(%(viewBox="#{viewbox}"))
        end
      end
    end
  end
end
