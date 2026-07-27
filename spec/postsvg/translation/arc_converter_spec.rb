# frozen_string_literal: true

require "spec_helper"

RSpec.describe Postsvg::Translation::ArcConverter do
  describe ".endpoint_to_center" do
    it "converts a simple right-arc to center parametrization" do
      # Arc from (10,0) to (-10,0) on a unit-radius circle centered at (0,0).
      cx, cy, rx, ry, _psi, theta1, theta2 = described_class.endpoint_to_center(
        x1: 10, y1: 0, rx: 10, ry: 10, x_axis_rotation: 0,
        large_arc: false, sweep: false, x2: -10, y2: 0
      )
      expect(cx).to be_within(0.001).of(0.0)
      expect(cy).to be_within(0.001).of(0.0)
      expect(rx).to be_within(0.001).of(10.0)
      expect(ry).to be_within(0.001).of(10.0)
      expect(theta1.abs).to be_within(0.01).of(0.0)
      expect(theta2.abs).to be_within(0.01).of(180.0)
    end

    it "scales up radii when too small to connect endpoints" do
      # Endpoints 100 units apart, radius 1 → must scale to 50.
      _cx, _cy, rx, ry, = described_class.endpoint_to_center(
        x1: 0, y1: 0, rx: 1, ry: 1, x_axis_rotation: 0,
        large_arc: false, sweep: false, x2: 100, y2: 0
      )
      expect(rx).to be >= 50.0
      expect(ry).to be >= 50.0
    end
  end
end
