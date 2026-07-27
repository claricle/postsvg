# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      class EllipseHandler
        extend Shared

        def self.call(element, context)
          context.emitter.emit(Model::Operators::GraphicsState::Gsave.new)
          emit_transform(element, context)
          context.emitter.emit(Model::Operators::Path::Newpath.new)
          cx = element.cx
          cy = element.cy
          rx = element.rx
          ry = element.ry
          # Approximate ellipse with scale + arc.
          if rx.to_f.positive? && ry.to_f.positive?
            scale = rx / ry
            context.emitter.emit(Model::Operators::Transformations::Translate.new(tx: cx, ty: cy))
            context.emitter.emit(Model::Operators::Transformations::Scale.new(sx: scale, sy: 1))
            context.emitter.emit(Model::Operators::Path::Arc.new(x: 0, y: 0, radius: ry, angle1: 0, angle2: 360))
          end
          emit_paint(element, context)
          context.emitter.emit(Model::Operators::GraphicsState::Grestore.new)
          expand_bbox(context, cx - rx, cy - ry, cx + rx, cy + ry)
        end
      end
    end
  end
end
