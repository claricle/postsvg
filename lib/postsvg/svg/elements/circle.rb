# frozen_string_literal: true

module Postsvg
  module Svg
    module Elements
      class Circle < Element
        ELEMENT_NAME = "circle"
        register ELEMENT_NAME, self

        attr_reader :cx, :cy, :r, :fill, :stroke_paint, :stroke

        def initialize(cx:, cy:, r:, fill:, stroke_paint:, stroke:, **rest)
          super(**rest)
          @cx = cx
          @cy = cy
          @r = r
          @fill = fill
          @stroke_paint = stroke_paint
          @stroke = stroke
        end

        def self.from_node(node)
          new(cx: AttributeParser.number(node["cx"], default: 0),
              cy: AttributeParser.number(node["cy"], default: 0),
              r: AttributeParser.number(node["r"], default: 0),
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
