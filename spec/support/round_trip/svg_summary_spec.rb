# frozen_string_literal: true

require "spec_helper"

RSpec.describe RoundTrip::SvgSummary do
  {
    "translation" => ["translate(10 10)", "M 5 0 A 5 5 0 0 1 0 5",
                      [["M", 15, 90], ["A", 5, 5, 0, 0, 0, 10, 85]]],
    "nonuniform scale" => ["scale(2 3)", "M 5 0 A 5 5 0 0 1 0 5",
                           [["M", 10, 100], ["A", 15, 10, 90, 0, 0, 0, 85]]],
    "nested translations" => ["translate(10 10) translate(20 0)",
                              "M -15 0 A 5 5 0 0 1 -20 5",
                              [["M", 15, 90], ["A", 5, 5, 0, 0, 0, 10, 85]]],
  }.each do |description, (transform, path, expected)|
    it "includes the page reflection in arc endpoints and sweep with #{description}" do
      svg = <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
          <g transform="translate(0 100) scale(1 -1)">
            <g transform="#{transform}"><path d="#{path}"/></g>
          </g>
        </svg>
      SVG

      expect(described_class.call(svg).first.fetch(:geometry).fetch(:commands)).to eq(expected)
    end
  end
end
