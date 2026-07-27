# frozen_string_literal: true

module Postsvg
  module Svg
    module Elements
      class Rect < Element
        ELEMENT_NAME = "rect"
        register ELEMENT_NAME, self

        attr_reader :x, :y, :width, :height, :rx, :ry,
                    :fill, :stroke_paint, :stroke

        def initialize(x:, y:, width:, height:, rx:, ry:, fill:,
                       stroke_paint:, stroke:, **rest)
          super(**rest)
          @x = x
          @y = y
          @width = width
          @height = height
          @rx = rx
          @ry = ry
          @fill = fill
          @stroke_paint = stroke_paint
          @stroke = stroke
        end

        def self.from_node(node)
          new(x: AttributeParser.number(node["x"], default: 0),
              y: AttributeParser.number(node["y"], default: 0),
              width: AttributeParser.number(node["width"], default: 0),
              height: AttributeParser.number(node["height"], default: 0),
              rx: AttributeParser.number(node["rx"]),
              ry: AttributeParser.number(node["ry"]),
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
