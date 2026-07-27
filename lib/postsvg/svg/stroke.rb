# frozen_string_literal: true

module Postsvg
  module Svg
    # Stroke style value object. Width is a Float (default 1.0),
    # dasharray is an Array of Floats, dashoffset is a Float, linecap
    # / linejoin are Symbols.
    Stroke = Struct.new(:width, :dasharray, :dashoffset, :linecap, :linejoin,
                        :miterlimit, keyword_init: true) do
      def self.parse(node)
        width = AttributeParser.number(node["stroke-width"], default: 1.0)
        dasharray_raw = node["stroke-dasharray"]
        dasharray =
          if dasharray_raw && dasharray_raw != "none"
            AttributeParser.number_list(dasharray_raw)
          end
        dashoffset = AttributeParser.number(node["stroke-dashoffset"], default: 0.0)
        linecap = (node["stroke-linecap"] || "butt").to_sym
        linejoin = (node["stroke-linejoin"] || "miter").to_sym
        miterlimit = AttributeParser.number(node["stroke-miterlimit"], default: 10.0)
        new(width: width, dasharray: dasharray, dashoffset: dashoffset,
            linecap: linecap, linejoin: linejoin, miterlimit: miterlimit)
      end

      def default?
        width == 1.0 && dasharray.nil? && dashoffset.zero? &&
          linecap == :butt && linejoin == :miter && miterlimit == 10.0
      end
    end
  end
end
