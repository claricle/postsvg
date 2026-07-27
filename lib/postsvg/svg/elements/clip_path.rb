# frozen_string_literal: true

module Postsvg
  module Svg
    module Elements
      class ClipPath < Element
        ELEMENT_NAME = "clipPath"
        register ELEMENT_NAME, self

        attr_reader :id, :children

        def initialize(id:, children: [], **rest)
          super(**rest)
          @id = id
          @children = children.freeze
        end

        def self.from_node(node)
          new(id: node["id"],
              children: node.element_children.map { |c| Element.from_node(c) },
              attributes: Elements.node_attributes(node))
        end
      end
    end
  end
end
