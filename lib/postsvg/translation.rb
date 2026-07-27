# frozen_string_literal: true

module Postsvg
  # SVG → PS translation layer. Consumes Svg::* value objects and
  # produces a Model::Program whose records a Serializer can write to
  # PS source. The model is the single source of truth: handlers
  # build records; the serializer consumes them later.
  module Translation
    autoload :PsRenderer, "postsvg/translation/ps_renderer"
    autoload :HandlerRegistry, "postsvg/translation/handler_registry"
    autoload :Context, "postsvg/translation/context"
    autoload :RecordEmitter, "postsvg/translation/record_emitter"
    autoload :Handlers, "postsvg/translation/handlers"
    autoload :BoundingBox, "postsvg/translation/bounding_box"
    autoload :ArcConverter, "postsvg/translation/arc_converter"
  end
end
