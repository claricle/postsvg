# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      class ImageHandler
        extend Shared

        def self.call(element, context)
          # Raster image support is tracked in TODO.roadmap/21-images.md.
          # For now, emit a comment so the serialized PS file has a
          # visible marker of the elided content.
          element.href || "(none)"
          context.emitter.emit(Model::UnknownOperator.new(keyword: "image"))
          expand_bbox(context, element.x, element.y, element.x + element.width,
                      element.y + element.height)
        end
      end
    end
  end
end
