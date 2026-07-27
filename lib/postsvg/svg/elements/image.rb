# frozen_string_literal: true

module Postsvg
  module Svg
    module Elements
      class Image < Element
        ELEMENT_NAME = "image"
        register ELEMENT_NAME, self

        attr_reader :x, :y, :width, :height, :href

        def initialize(x:, y:, width:, height:, href:, **rest)
          super(**rest)
          @x = x
          @y = y
          @width = width
          @height = height
          @href = href
        end

        def self.from_node(node)
          href = node["href"] || node["xlink:href"]
          new(x: AttributeParser.number(node["x"], default: 0),
              y: AttributeParser.number(node["y"], default: 0),
              width: AttributeParser.number(node["width"], default: 0),
              height: AttributeParser.number(node["height"], default: 0),
              href: href,
              transform: TransformList.parse(node["transform"]),
              clip_path_id: Elements.parse_clip_path_id(node["clip-path"]),
              attributes: Elements.node_attributes(node))
        end
      end
    end
  end
end
