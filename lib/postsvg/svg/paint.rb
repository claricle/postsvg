# frozen_string_literal: true

module Postsvg
  module Svg
    # Paint value object: resolves a CSS-style paint value to either
    # a Color instance, a paint-server URL reference (gradient /
    # pattern id), or :none.
    Paint = Struct.new(:kind, :value, keyword_init: true) do
      def self.parse(text)
        return Paint.new(kind: :none) if text.nil? || text.strip == "none"

        if text&.start_with?("url(")
          id = text.match(/url\(\s*["']?#([^)\s"']+)/)
          return Paint.new(kind: :reference, value: id && id[1])
        end

        color = begin
          ::Postsvg::Color.parse(text.to_s)
        rescue ArgumentError
          nil
        end
        if color
          Paint.new(kind: :color, value: color)
        else
          Paint.new(kind: :none)
        end
      end

      def none? = kind == :none
      def reference? = kind == :reference
      def color? = kind == :color
    end
  end
end
