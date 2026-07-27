# frozen_string_literal: true

module Postsvg
  module Svg
    # Root value object produced by Svg::Parser. Carries the SVG root
    # element, the document's viewBox / width / height (parsed once),
    # and the ClipPathRegistry assembled from <defs>.
    class Document
      attr_reader :root_element, :viewbox, :width, :height, :clip_paths

      def initialize(root_element:, viewbox: nil, width: nil, height: nil,
                     clip_paths: ClipPathRegistry.empty)
        @root_element = root_element
        @viewbox = viewbox
        @width = width
        @height = height
        @clip_paths = clip_paths
        freeze
      end
    end
  end
end
