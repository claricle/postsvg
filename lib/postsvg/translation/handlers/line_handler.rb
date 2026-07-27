# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      class LineHandler
        extend Shared

        def self.call(element, context)
          context.emitter.emit(Model::Operators::GraphicsState::Gsave.new)
          emit_transform(element, context)
          emit_stroke(element, context)
          context.emitter.emit(Model::Operators::Path::Newpath.new)
          context.emitter.emit(Model::Operators::Path::Moveto.new(x: element.x1, y: element.y1))
          context.emitter.emit(Model::Operators::Path::Lineto.new(x: element.x2, y: element.y2))
          context.emitter.emit(Model::Operators::Painting::Stroke.new)
          context.emitter.emit(Model::Operators::GraphicsState::Grestore.new)
          expand_bbox(context, element.x1, element.y1, element.x2, element.y2)
        end
      end
    end
  end
end
