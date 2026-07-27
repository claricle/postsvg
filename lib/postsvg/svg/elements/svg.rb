# frozen_string_literal: true

module Postsvg
  module Svg
    module Elements
      class Svg < Element
        ELEMENT_NAME = "svg"
        register ELEMENT_NAME, self

        attr_reader :viewbox, :width, :height, :children

        def initialize(viewbox: nil, width: nil, height: nil, children: [],
**rest)
          super(**rest)
          @viewbox = viewbox
          @width = width
          @height = height
          @children = children.freeze
        end

        def self.from_node(node)
          children = node.element_children.map { |c| Element.from_node(c) }
          vb = node["viewBox"]&.split(/[\s,]+/)&.map(&:to_f)
          new(viewbox: (vb if vb&.length == 4),
              width: AttributeParser.length(node["width"]),
              height: AttributeParser.length(node["height"]),
              children: children,
              transform: TransformList.parse(node["transform"]),
              clip_path_id: parse_clip_path_id(node["clip-path"]))
        end

        def self.parse_clip_path_id(text)
          m = text&.match(/url\(\s*["']?#([^)\s"']+)/)
          m && m[1]
        end
        private_class_method :parse_clip_path_id
      end
    end
  end
end
