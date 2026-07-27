# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      class CircleHandler
        extend Shared

        def self.call(element, context)
          context.emitter.emit(Model::Operators::GraphicsState::Gsave.new)
          emit_transform(element, context)
          context.emitter.emit(Model::Operators::Path::Newpath.new)
          r = element.r
          cx = element.cx
          cy = element.cy
          if r.to_f.positive?
            context.emitter.emit(Model::Operators::Path::Arc.new(
              x: cx, y: cy, radius: r, angle1: 0, angle2: 360,
            ))
          end
          emit_paint(element, context)
          context.emitter.emit(Model::Operators::GraphicsState::Grestore.new)
          expand_bbox(context, cx - r, cy - r, cx + r, cy + r)
        end
      end
    end
  end
end
