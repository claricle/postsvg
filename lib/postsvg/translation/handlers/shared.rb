# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      # Helpers shared by every handler. Mixed into each handler
      # class via +extend Shared+ so handler bodies stay declarative.
      #
      # All element classes in Svg::Elements provide +fill+,
      # +stroke_paint+, +stroke+, and +transform+ getters (returning
      # nil when not applicable). This module relies on those getters
      # existing — no +respond_to?+ checks.
      module Shared
        # Emit paint setup + paint terminator(s) for an element. When
        # the element has only fill, emits color + fill. When only
        # stroke, emits color + stroke. When both, emits a
        # gsave / setrgbcolor(fill) / fill / grestore /
        # setrgbcolor(stroke) / stroke sequence so each paint uses
        # the right color.
        def emit_paint(element, context)
          fill_paint = element.fill
          stroke_paint = element.stroke_paint
          fill_on = fill_paint && fill_paint.color?
          stroke_on = stroke_paint && stroke_paint.color?

          if fill_on && stroke_on
            emit_fill(element, context)
            context.emitter.emit(Model::Operators::GraphicsState::Gsave.new)
            context.emitter.emit(Model::Operators::Painting::Fill.new)
            context.emitter.emit(Model::Operators::GraphicsState::Grestore.new)
            emit_stroke(element, context)
            context.emitter.emit(Model::Operators::Painting::Stroke.new)
          elsif fill_on
            emit_fill(element, context)
            context.emitter.emit(Model::Operators::Painting::Fill.new)
          elsif stroke_on
            emit_stroke(element, context)
            context.emitter.emit(Model::Operators::Painting::Stroke.new)
          else
            # No explicit paint — fill with current color (default).
            context.emitter.emit(Model::Operators::Painting::Fill.new)
          end
        end

        # Convenience for handlers that want to set up colors without
        # emitting a paint terminator (e.g. LineHandler which always
        # strokes).
        def emit_paint_setup(element, context)
          emit_fill(element, context)
          emit_stroke(element, context)
        end

        def emit_fill(element, context)
          paint = element.fill
          return unless paint && paint.color?

          color = paint.value
          if color.gray?
            context.emitter.emit(Model::Operators::Color::Setgray.new(gray: color.gray_level))
          else
            context.emitter.emit(Model::Operators::Color::Setrgbcolor.new(
              red: color.red / 255.0, green: color.green / 255.0, blue: color.blue / 255.0,
            ))
          end
        end

        def emit_stroke(element, context)
          paint = element.stroke_paint
          return unless paint && paint.color?

          color = paint.value
          context.emitter.emit(Model::Operators::Color::Setrgbcolor.new(
            red: color.red / 255.0, green: color.green / 255.0, blue: color.blue / 255.0,
          ))
          stroke = element.stroke
          return unless stroke

          context.emitter.emit(Model::Operators::GraphicsState::Setlinewidth.new(width: stroke.width)) if stroke.width
          if stroke.linecap
            code = { butt: 0, round: 1, square: 2 }[stroke.linecap.to_sym]
            context.emitter.emit(Model::Operators::GraphicsState::Setlinecap.new(cap_code: code)) if code
          end
          if stroke.linejoin
            code = { miter: 0, round: 1, bevel: 2 }[stroke.linejoin.to_sym]
            context.emitter.emit(Model::Operators::GraphicsState::Setlinejoin.new(join_code: code)) if code
          end
        end

        def emit_transform(element, context)
          transform = element.transform
          return unless transform && !transform.empty?

          transform.matrices.each do |matrix|
            context.emitter.emit(Model::Operators::Transformations::Concat.new(matrix: [
              matrix.a, matrix.b, matrix.c, matrix.d, matrix.e, matrix.f,
            ]))
          end
        end

        def expand_bbox(context, *points)
          xs = points.each_slice(2).map(&:first)
          ys = points.each_slice(2).map(&:last)
          return if xs.empty?

          context.expand_bbox!((xs.min..xs.max), (ys.min..ys.max))
        end
      end
    end
  end
end
