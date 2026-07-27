# frozen_string_literal: true

module Postsvg
  # SVG domain model. Built once from a Nokogiri-parsed document;
  # consumed by the Translation layer (SVG -> PS).
  #
  # Svg::* value objects know nothing about PostScript. Their job is
  # to present SVG semantics in a typed, immutable form.
  module Svg
    autoload :Element, "postsvg/svg/element"
    autoload :OpenElement, "postsvg/svg/element"
    autoload :Document, "postsvg/svg/document"
    autoload :Parser, "postsvg/svg/parser"
    autoload :AttributeParser, "postsvg/svg/attribute_parser"
    autoload :Paint, "postsvg/svg/paint"
    autoload :Stroke, "postsvg/svg/stroke"
    autoload :TransformList, "postsvg/svg/transform_list"
    autoload :PathData, "postsvg/svg/path_data"
    autoload :ClipPathRegistry, "postsvg/svg/clip_path_registry"
    autoload :Elements, "postsvg/svg/elements"
  end
end
