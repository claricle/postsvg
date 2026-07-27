# frozen_string_literal: true

module Postsvg
  module Svg
    module Elements
      class Defs < Element
        ELEMENT_NAME = "defs"
        register ELEMENT_NAME, self

        attr_reader :children

        def initialize(children: [], **rest)
          super(**rest)
          @children = children.freeze
        end

        def self.from_node(node)
          new(children: node.element_children.map { |c| Element.from_node(c) },
              attributes: Elements.node_attributes(node))
        end
      end
    end
  end
end
