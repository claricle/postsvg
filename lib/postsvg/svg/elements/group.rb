# frozen_string_literal: true

module Postsvg
  module Svg
    module Elements
      class Group < Element
        ELEMENT_NAME = "g"
        register ELEMENT_NAME, self

        attr_reader :children

        def initialize(children: [], **rest)
          super(**rest)
          @children = children.freeze
        end

        def self.from_node(node)
          new(children: node.element_children.map { |c| Element.from_node(c) },
              transform: TransformList.parse(node["transform"]),
              clip_path_id: Elements.parse_clip_path_id(node["clip-path"]),
              attributes: Elements.node_attributes(node))
        end
      end

      def self.node_attributes(node)
        attrs = {}
        node.attribute_nodes.each { |a| attrs[a.name] = a.value }
        attrs
      end

      def self.parse_clip_path_id(text)
        m = text&.match(/url\(\s*["']?#([^)\s"']+)/)
        m && m[1]
      end
    end
  end
end
