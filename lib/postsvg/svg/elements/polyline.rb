# frozen_string_literal: true

module Postsvg
  module Svg
    module Elements
      class Polyline < Element
        ELEMENT_NAME = "polyline"
        register ELEMENT_NAME, self

        attr_reader :points, :fill, :stroke_paint, :stroke

        def initialize(points:, fill:, stroke_paint:, stroke:, **rest)
          super(**rest)
          @points = points.freeze
          @fill = fill
          @stroke_paint = stroke_paint
          @stroke = stroke
        end

        def self.from_node(node)
          new(points: AttributeParser.number_list(node["points"]),
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
