# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      class PolylineHandler
        extend Shared

        def self.call(element, context)
          context.emitter.emit(Model::Operators::GraphicsState::Gsave.new)
          emit_transform(element, context)
          emit_stroke(element, context)
          context.emitter.emit(Model::Operators::Path::Newpath.new)
          points = element.points
          points.each_slice(2).with_index do |(x, y), idx|
            if idx.zero?
              context.emitter.emit(Model::Operators::Path::Moveto.new(x: x, y: y))
            else
              context.emitter.emit(Model::Operators::Path::Lineto.new(x: x, y: y))
            end
          end
          context.emitter.emit(Model::Operators::Painting::Stroke.new)
          context.emitter.emit(Model::Operators::GraphicsState::Grestore.new)
          xs = points.each_slice(2).map(&:first)
          ys = points.each_slice(2).map(&:last)
          expand_bbox(context, xs.min, ys.min, xs.max, ys.max) if xs.any?
        end
      end
    end
  end
end
