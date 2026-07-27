# frozen_string_literal: true

require "postsvg"

RSpec.describe Postsvg::FormatNumber do
  it "formats integers without decimals" do
    expect(described_class.call(10)).to eq("10")
  end

  it "formats floats to 4 decimals with trailing zeros stripped" do
    expect(described_class.call(3.14)).to eq("3.14")
    expect(described_class.call(3.14159265)).to eq("3.1416")
    expect(described_class.call(2.5)).to eq("2.5")
  end

  it "normalizes negative zero" do
    expect(described_class.call(-0.0)).to eq("0")
  end

  it "raises on non-finite numbers" do
    expect do
      described_class.call(Float::NAN)
    end.to raise_error(ArgumentError)
    expect do
      described_class.call(Float::INFINITY)
    end.to raise_error(ArgumentError)
  end
end
