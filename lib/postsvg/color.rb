# frozen_string_literal: true

module Postsvg
  # Immutable RGB color value object. Use the constructors (+.rgb+,
  # +.gray+, +.cmyk+, +.parse+) instead of +new+ when constructing from
  # other color models; they normalize to integer [0, 255] channels.
  class Color
    include Comparable

    attr_reader :red, :green, :blue

    def self.clamp_byte(value)
      Integer === value ? value.clamp(0, 255) : value.to_i.clamp(0, 255)
    end

    def self.scale_unit_to_byte(value)
      (value.clamp(0.0, 1.0) * 255.0).round
    end

    def initialize(red, green, blue)
      @red = Color.clamp_byte(red)
      @green = Color.clamp_byte(green)
      @blue = Color.clamp_byte(blue)
      freeze
    end

    # RGB triple in PS-native [0.0, 1.0] floats.
    def self.rgb(r, g, b)
      new(scale_unit_to_byte(r), scale_unit_to_byte(g), scale_unit_to_byte(b))
    end

    # Gray in [0.0, 1.0].
    def self.gray(level)
      v = scale_unit_to_byte(level)
      new(v, v, v)
    end

    # CMYK in [0.0, 1.0]. Conversion matches PLRM §8.2.4 simplified
    # formula; not colorimetrically exact.
    def self.cmyk(c, m, y, k)
      new(
        scale_unit_to_byte((1 - c) * (1 - k)),
        scale_unit_to_byte((1 - m) * (1 - k)),
        scale_unit_to_byte((1 - y) * (1 - k)),
      )
    end

    # Parse CSS / SVG color notations: #rgb, #rrggbb, rgb(r, g, b),
    # rgb(r g b / a), named colors (X11 subset).
    def self.parse(text)
      return text if text.is_a?(Color)

      case text.to_s.downcase
      when /\A#([0-9a-f]{6})\z/
        hex = ::Regexp.last_match(1)
        new(hex[0, 2].to_i(16), hex[2, 2].to_i(16), hex[4, 2].to_i(16))
      when /\A#([0-9a-f]{3})\z/
        hex = ::Regexp.last_match(1)
        new((hex[0] * 2).to_i(16), (hex[1] * 2).to_i(16), (hex[2] * 2).to_i(16))
      when /\argb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/
        new(::Regexp.last_match(1).to_i, ::Regexp.last_match(2).to_i, ::Regexp.last_match(3).to_i)
      when /\argb\(\s*(\d+)\s+(\d+)\s+(\d+)/
        new(::Regexp.last_match(1).to_i, ::Regexp.last_match(2).to_i, ::Regexp.last_match(3).to_i)
      when "none", "transparent"
        nil
      else
        rgb = NAMED_COLORS[text.to_s]
        return new(*rgb) if rgb

        raise ArgumentError, "unrecognized color: #{text.inspect}"
      end
    end

    def gray?
      red == green && green == blue
    end

    def gray_level
      (red + green + blue) / 765.0
    end

    def to_rgb_unit
      [red / 255.0, green / 255.0, blue / 255.0]
    end

    def to_svg
      format("#%02x%02x%02x", red, green, blue)
    end

    def to_ps_rgb
      to_rgb_unit.map { |c| FormatNumber.call(c) }.join(" ")
    end

    def to_ps_gray
      raise ArgumentError, "color is not gray" unless gray?

      FormatNumber.call(gray_level)
    end

    def <=>(other)
      return nil unless other.is_a?(Color)

      [red, green, blue] <=> [other.red, other.green, other.blue]
    end

    def hash
      [red, green, blue].hash
    end

    def eql?(other)
      other.is_a?(Color) && other.red == red && other.green == green && other.blue == blue
    end
    alias == eql?

    NAMED_COLORS = {
      "black" => [0, 0, 0], "white" => [255, 255, 255],
      "red" => [255, 0, 0], "green" => [0, 128, 0], "blue" => [0, 0, 255],
      "yellow" => [255, 255, 0], "cyan" => [0, 255, 255],
      "magenta" => [255, 0, 255], "gray" => [128, 128, 128],
      "grey" => [128, 128, 128], "silver" => [192, 192, 192],
      "maroon" => [128, 0, 0], "olive" => [128, 128, 0],
      "navy" => [0, 0, 128], "purple" => [128, 0, 128],
      "teal" => [0, 128, 128], "lime" => [0, 255, 0],
      "aqua" => [0, 255, 255], "fuchsia" => [255, 0, 255],
      "orange" => [255, 165, 0], "pink" => [255, 192, 203],
      "brown" => [165, 42, 42],
    }.freeze

    BLACK = Color.new(0, 0, 0).freeze
    WHITE = Color.new(255, 255, 255).freeze
  end
end
