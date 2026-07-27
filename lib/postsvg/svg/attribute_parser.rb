# frozen_string_literal: true

module Postsvg
  module Svg
    # Helpers for parsing presentation attributes into typed values.
    # Used by Element.from_node factories.
    module AttributeParser
      module_function

      # Parse a length attribute ("10", "10px", "10pt", "50%").
      # Returns a Float. Percentage values resolve to nil — the caller
      # must know the reference dimension.
      def length(text)
        return nil if text.nil? || text.empty?

        match = text.strip.match(/\A(-?\d+(?:\.\d+)?)(px|pt|in|cm|mm|em|ex|%)?\z/)
        return nil unless match

        return nil if match[2] == "%"

        value = match[1].to_f
        case match[2]
        when "pt" then value * (1.0 / 72.0) * 72.0 # PS uses points natively
        when "in" then value * 72.0
        when "cm" then value * (72.0 / 2.54)
        when "mm" then value * (72.0 / 25.4)
        else value
        end
      end

      def number_list(text)
        return [] if text.nil? || text.empty?

        text.scan(/-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?/).map(&:to_f)
      end

      def number(text, default: nil)
        return default if text.nil? || text.empty?

        match = text.strip.match(/\A(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)\z/)
        match ? match[1].to_f : default
      end
    end
  end
end
