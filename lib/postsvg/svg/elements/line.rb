# frozen_string_literal: true

module Postsvg
  module Svg
    module Elements
      class Line < Element
        ELEMENT_NAME = "line"
        register ELEMENT_NAME, self

        attr_reader :x1, :y1, :x2, :y2, :stroke_paint, :stroke

        def initialize(x1:, y1:, x2:, y2:, stroke_paint:, stroke:, **rest)
          super(**rest)
          @x1 = x1
          @y1 = y1
          @x2 = x2
          @y2 = y2
          @stroke_paint = stroke_paint
          @stroke = stroke
        end

        def self.from_node(node)
          new(x1: AttributeParser.number(node["x1"], default: 0),
              y1: AttributeParser.number(node["y1"], default: 0),
              x2: AttributeParser.number(node["x2"], default: 0),
              y2: AttributeParser.number(node["y2"], default: 0),
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
