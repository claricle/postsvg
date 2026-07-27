# frozen_string_literal: true

module Postsvg
  module Svg
    module Elements
      class Polygon < Polyline
        ELEMENT_NAME = "polygon"
        register ELEMENT_NAME, self
      end
    end
  end
end
