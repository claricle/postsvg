# frozen_string_literal: true

module Postsvg
  module Translation
    # Mutable translation context carried through the SVG tree walk.
    # Holds the emitter, the graphics state stack (so handlers can
    # emit gsave/grestore around transforms), and the bounding box
    # accumulator.
    class Context
      attr_reader :emitter, :graphics, :bounding_box, :options,
                  :clip_path_registry

      def initialize(emitter: RecordEmitter.new,
                     graphics: GraphicsStack.new,
                     bounding_box: BoundingBox.empty,
                     clip_path_registry: ::Postsvg::Svg::ClipPathRegistry.empty,
                     options: {})
        @emitter = emitter
        @graphics = graphics
        @bounding_box = bounding_box
        @clip_path_registry = clip_path_registry
        @options = options.freeze
      end

      def expand_bbox!(x_range, y_range)
        @bounding_box = @bounding_box.expand(x_range, y_range)
      end

      def eps?
        options.fetch(:eps, false)
      end
    end
  end
end
