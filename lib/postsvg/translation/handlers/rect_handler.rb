# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      class RectHandler
        extend Shared

        def self.call(element, context)
          context.emitter.emit(Model::Operators::GraphicsState::Gsave.new)
          emit_transform(element, context)
          context.emitter.emit(Model::Operators::Path::Newpath.new)
          x, y = element.x, element.y
          w, h = element.width, element.height
          context.emitter.emit(Model::Operators::Path::Moveto.new(x: x, y: y))
          context.emitter.emit(Model::Operators::Path::Rlineto.new(dx: w, dy: 0))
          context.emitter.emit(Model::Operators::Path::Rlineto.new(dx: 0, dy: h))
          context.emitter.emit(Model::Operators::Path::Rlineto.new(dx: -w, dy: 0))
          context.emitter.emit(Model::Operators::Path::Closepath.new)
          emit_paint(element, context)
          context.emitter.emit(Model::Operators::GraphicsState::Grestore.new)
          expand_bbox(context, x, y, x + w, y + h)
        end
      end
    end
  end
end
