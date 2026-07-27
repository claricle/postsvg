# frozen_string_literal: true

module Postsvg
  # Single source of truth for formatting numbers in both directions.
  #
  # - Integers print without a trailing ".0".
  # - Floats print to 4 decimals, trailing zeros stripped.
  # - -0 normalizes to 0 (so viewBoxes don't read "0 -0 100 100").
  # - +Inf / -Inf / NaN raise ArgumentError; callers should validate.
  module FormatNumber
    module_function

    def call(value)
      raise ArgumentError, "non-finite number: #{value.inspect}" unless value.finite?

      normalized = value.zero? ? 0.0 : value
      return normalized.to_i.to_s if normalized == normalized.to_i

      format("%.4f", normalized).sub(/\.?0+$/, "")
    end
  end
end
