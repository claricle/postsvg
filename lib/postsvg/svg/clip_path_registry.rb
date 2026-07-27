# frozen_string_literal: true

module Postsvg
  module Svg
    # Indexes <clipPath id="..."> definitions in a document so handlers
    # can resolve url(#id) references without re-walking the tree.
    class ClipPathRegistry
      attr_reader :by_id

      def initialize(by_id = {})
        @by_id = by_id.dup.freeze
        freeze
      end

      def self.empty
        @empty ||= new({})
      end

      def lookup(id)
        @by_id[id]
      end

      def key?(id)
        @by_id.key?(id)
      end

      # Build a registry by scanning +root+ for <clipPath> children.
      def self.from_node(root)
        registry = {}
        root.xpath(".//*[local-name()='clipPath']").each do |node|
          id = node["id"]
          next unless id

          # Concatenate the d attributes of all child <path> elements
          # in document order. Other shape children are converted to
          # path data lazily; for now we only support <path>.
          ds = node.xpath(".//*[local-name()='path']").filter_map do |p|
            p["d"]
          end
          registry[id] = ds.join(" ") unless ds.empty?
        end
        new(registry)
      end
    end
  end
end
