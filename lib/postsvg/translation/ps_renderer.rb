# frozen_string_literal: true

module Postsvg
  module Translation
    # Top-level orchestrator: takes an Svg::Document, walks its element
    # tree via a HandlerRegistry, and produces a Model::Program whose
    # body the Serializer consumes.
    class PsRenderer
      DEFAULT_REGISTRY = HandlerRegistry.new
      @default_registered = false

      class << self
        attr_reader :default_registered

        # Idempotent: only registers once. Called automatically by
        # +default_registry+ before each translate, so callers don't
        # need to remember to invoke it.
        def register_default_handlers!
          return if @default_registered

          DEFAULT_REGISTRY.register(Svg::Elements::Svg, Handlers::SvgHandler)
          DEFAULT_REGISTRY.register(Svg::Elements::Group, Handlers::GroupHandler)
          DEFAULT_REGISTRY.register(Svg::Elements::Path, Handlers::PathHandler)
          DEFAULT_REGISTRY.register(Svg::Elements::Rect, Handlers::RectHandler)
          DEFAULT_REGISTRY.register(Svg::Elements::Circle, Handlers::CircleHandler)
          DEFAULT_REGISTRY.register(Svg::Elements::Ellipse, Handlers::EllipseHandler)
          DEFAULT_REGISTRY.register(Svg::Elements::Line, Handlers::LineHandler)
          DEFAULT_REGISTRY.register(Svg::Elements::Polyline, Handlers::PolylineHandler)
          DEFAULT_REGISTRY.register(Svg::Elements::Polygon, Handlers::PolygonHandler)
          DEFAULT_REGISTRY.register(Svg::Elements::Text, Handlers::TextHandler)
          DEFAULT_REGISTRY.register(Svg::Elements::Image, Handlers::ImageHandler)
          DEFAULT_REGISTRY.register(Svg::Elements::Defs, Handlers::DefsHandler)
          DEFAULT_REGISTRY.register(Svg::Elements::ClipPath, Handlers::ClipPathHandler)
          DEFAULT_REGISTRY.register(Svg::OpenElement, Handlers::OpenHandler)
          @default_registered = true
        end

        # Public accessor: returns the default registry after ensuring
        # handlers are registered. Use this in handlers instead of
        # reaching for the constant directly.
        def default_registry
          register_default_handlers!
          DEFAULT_REGISTRY
        end
      end

      def self.call(document, eps: false, registry: nil)
        registry ||= default_registry
        new(document, eps: eps, registry: registry).call
      end

      attr_reader :document, :eps, :registry

      def initialize(document, eps:, registry:)
        @document = document
        @eps = eps
        @registry = registry
      end

      def call
        emitter = RecordEmitter.new
        bbox = compute_viewport_bbox
        context = Context.new(emitter: emitter,
                              bounding_box: bbox,
                              clip_path_registry: document.clip_paths,
                              options: { eps: eps })
        dispatch(document.root_element, context)
        build_program(emitter, context)
      end

      private

      def compute_viewport_bbox
        if document.viewbox
          llx, lly, urx, ury = document.viewbox
          BoundingBox.new(min_x: llx, min_y: lly, max_x: urx, max_y: ury)
        elsif document.width && document.height
          BoundingBox.new(min_x: 0, min_y: 0, max_x: document.width,
                          max_y: document.height)
        else
          BoundingBox.empty
        end
      end

      def dispatch(element, context)
        registry.translate(element, context)
      end

      def build_program(emitter, context)
        bbox = context.bounding_box
        header_bbox =
          if bbox.empty?
            [0, 0, 595, 842] # A4 fallback
          else
            bbox.to_a
          end
        header = Model::Program::Header.new(
          bounding_box: header_bbox,
          epsf: eps,
          title: "Translated by Postsvg #{::Postsvg::VERSION}",
        )
        Model::Program.new(header: header, body: emitter.records)
      end
    end
  end
end
