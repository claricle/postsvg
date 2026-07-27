# frozen_string_literal: true

module Postsvg
  module Svg
    # Base value object for an SVG element. Subclasses (Svg::Elements::*)
    # carry typed semantic fields; the base provides a uniform interface
    # for the translation layer's dispatch.
    #
    # Element instances are immutable: built once from a Nokogiri node
    # via the .from_node factory. The node is not retained.
    #
    # Every element exposes `children`, `transform`, `clip_path_id`,
    # `fill`, `stroke_paint`, `stroke`, `stroke_paint_value`, all
    # defaulting to nil / []. Subclasses override only the attributes
    # that are actually present in the source element. This lets the
    # Translation::Handlers::Shared helpers call any of these methods
    # uniformly without resorting to `respond_to?` type checks.
    class Element
      ELEMENT_NAME = "abstract"

      attr_reader :transform, :clip_path_id, :attributes,
                  :children, :fill, :stroke_paint, :stroke

      def initialize(transform: nil, clip_path_id: nil, attributes: {},
                     children: [], fill: nil, stroke_paint: nil, stroke: nil)
        @transform = transform
        @clip_path_id = clip_path_id
        @attributes = attributes.dup.freeze
        @children = children.freeze
        @fill = fill
        @stroke_paint = stroke_paint
        @stroke = stroke
      end

      # Default paint: black fill, no stroke. Handlers can override.
      def default_fill
        nil
      end

      def element_name
        self.class::ELEMENT_NAME
      end

      # Registry: SVG element name -> Element subclass. OCP: register
      # new subclasses via Element.register("rect", Elements::Rect)
      # instead of editing a switch. Backed by a constant Hash so
      # subclasses share a single registry regardless of +self+ at
      # the call site.
      REGISTRY = {}

      class << self
        def registry
          Postsvg::Svg::Element::REGISTRY
        end

        def register(element_name, subclass)
          registry[element_name] = subclass
        end

        def from_node(node)
          subclass = registry[node.name]
          return subclass.from_node(node) if subclass

          OpenElement.new(name: node.name,
                          children: node.element_children.map do |c|
                            from_node(c)
                          end)
        end
      end
    end

    # Fallback for unknown SVG element types. Carries the element name
    # so handlers can skip or warn; carries children so traversal
    # still descends into known subtrees.
    class OpenElement < Element
      ELEMENT_NAME = "open"

      attr_reader :name

      def initialize(name:, **rest)
        super(**rest)
        @name = name
      end
    end
  end
end
