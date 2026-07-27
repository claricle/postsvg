# frozen_string_literal: true

module Postsvg
  module Translation
    # Accumulates the SVG content's geometric bounds as the SVG tree
    # is walked. Used to write the +%%BoundingBox+ DSC comment in the
    # serialized output.
    class BoundingBox
      attr_reader :min_x, :min_y, :max_x, :max_y

      def initialize(min_x:, min_y:, max_x:, max_y:)
        @min_x = min_x
        @min_y = min_y
        @max_x = max_x
        @max_y = max_y
        freeze
      end

      def self.empty
        new(min_x: nil, min_y: nil, max_x: nil, max_y: nil)
      end

      def empty?
        @min_x.nil?
      end

      def expand(x_range, y_range)
        return self if x_range.nil? || y_range.nil?

        new_min_x = [(empty? ? x_range.begin : @min_x), x_range.begin].compact.min
        new_max_x = [(empty? ? x_range.end : @max_x), x_range.end].compact.max
        new_min_y = [(empty? ? y_range.begin : @min_y), y_range.begin].compact.min
        new_max_y = [(empty? ? y_range.end : @max_y), y_range.end].compact.max
        BoundingBox.new(min_x: new_min_x, min_y: new_min_y, max_x: new_max_x, max_y: new_max_y)
      end

      def to_a
        empty? ? [] : [@min_x, @min_y, @max_x, @max_y]
      end

      def width
        empty? ? 0 : @max_x - @min_x
      end

      def height
        empty? ? 0 : @max_y - @min_y
      end

      def to_dsc_comment
        return nil if empty?

        "%s %s %s %s" % [
          FormatNumber.call(@min_x), FormatNumber.call(@min_y),
          FormatNumber.call(@max_x), FormatNumber.call(@max_y),
        ]
      end
    end
  end
end
