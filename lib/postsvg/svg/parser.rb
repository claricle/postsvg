# frozen_string_literal: true

require "nokogiri"

module Postsvg
  module Svg
    # Parses an SVG document via Nokogiri and produces an Svg::Document.
    # Pure: no I/O, no global state.
    class Parser
      def self.call(svg_string)
        doc = Nokogiri::XML(svg_string, &:noblanks)
        root = doc.root
        raise TranslationError, "no root element in SVG" unless root

        Elements.load_all! # populate Element.registry with all known tag handlers
        root_element = Element.from_node(root)
        viewbox, width, height = extract_root_dimensions(root)
        clip_paths = ClipPathRegistry.from_node(root)
        Document.new(root_element: root_element,
                     viewbox: viewbox,
                     width: width,
                     height: height,
                     clip_paths: clip_paths)
      end

      def self.extract_root_dimensions(root)
        vb = root["viewBox"]
        width = root["width"]
        height = root["height"]
        parsed_vb =
          if vb
            nums = vb.split(/\s+|,/).map(&:to_f)
            nums if nums.length == 4
          end
        [parsed_vb, width&.to_f, height&.to_f]
      end
    end
  end
end
