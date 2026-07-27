# frozen_string_literal: true

require "postsvg"

RSpec.describe Postsvg::Matrix do
  describe "#identity?" do
    it "is true for a default matrix" do
      expect(Postsvg::Matrix.new).to be_identity
    end

    it "is false after translate" do
      expect(Postsvg::Matrix.new.translate(10, 20)).not_to be_identity
    end
  end

  describe "#translate / #scale / #rotate" do
    it "compose via multiply" do
      m = Postsvg::Matrix.new.translate(5, 5).scale(2, 2)
      p = m.apply_point(1, 1)
      expect(p[:x]).to eq(7)
      expect(p[:y]).to eq(7)
    end

    it "rotate by 90deg maps (1,0) to (0,1)" do
      m = Postsvg::Matrix.new.rotate(90)
      p = m.apply_point(1, 0)
      expect(p[:x]).to be_within(1e-9).of(0)
      expect(p[:y]).to be_within(1e-9).of(1)
    end
  end

  describe "#invert" do
    it "round-trips through invert" do
      m = Postsvg::Matrix.new.translate(5, 7).scale(2, 3).rotate(45)
      inv = m.invert
      composed = m.multiply(inv)
      expect(composed.apply_point(10, 20)[:x]).to be_within(1e-9).of(10)
      expect(composed.apply_point(10, 20)[:y]).to be_within(1e-9).of(20)
    end
  end
end
