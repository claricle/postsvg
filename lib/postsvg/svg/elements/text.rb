# frozen_string_literal: true

module Postsvg
  module Svg
    module Elements
      class Text < Element
        ELEMENT_NAME = "text"
        register ELEMENT_NAME, self

        attr_reader :x, :y, :content, :font_family, :font_size,
                    :fill, :stroke_paint, :stroke

        def initialize(x:, y:, content:, font_family:, font_size:,
                       fill:, stroke_paint:, stroke:, **rest)
          super(**rest)
          @x = x
          @y = y
          @content = content
          @font_family = font_family
          @font_size = font_size
          @fill = fill
          @stroke_paint = stroke_paint
          @stroke = stroke
        end

        def self.from_node(node)
          new(x: AttributeParser.number(node["x"], default: 0),
              y: AttributeParser.number(node["y"], default: 0),
              content: node.text,
              font_family: node["font-family"] || "Helvetica",
              font_size: AttributeParser.number(node["font-size"], default: 12),
              fill: Paint.parse(node["fill"]),
              stroke_paint: Paint.parse(node["stroke"]),
              stroke: Stroke.parse(node),
              transform: TransformList.parse(node["transform"]),
              clip_path_id: Elements.parse_clip_path_id(node["clip-path"]),
              attributes: Elements.node_attributes(node))
        end
      end
    end
  end
end
