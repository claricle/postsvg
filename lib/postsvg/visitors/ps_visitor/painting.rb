# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Painting operator handlers. Each flushes the current path
      # through the SvgBuilder with the appropriate mode and color,
      # then resets the path.
      module Painting
        def visit_stroke(_op, _ctx)
          flush_path(:stroke)
          @path.reset
        end

        def visit_fill(_op, _ctx)
          flush_path(:fill)
          @path.reset
        end

        def visit_eofill(_op, _ctx)
          flush_path(:fill)
          @path.reset
        end

        def visit_clip(_op, _ctx)
          return if @path.empty?

          path_d = @path.to_path_d
          clip_id = @builder.register_clip_path(path_d)
          @graphics.update(clip_paths: @graphics.current.clip_paths + [clip_id])
          @path.reset
        end

        def visit_eoclip(_op, _ctx)
          visit_clip(nil, nil)
        end

        private

        # Emit the current path as a <path> element. Takes the current
        # CTM into account: when the CTM is not identity, wraps in a
        # <g transform="..."> and pre-decomposes the transform.
        def flush_path(mode)
          return if @path.empty?

          d = @path.to_path_d
          ctx = @graphics.current
          transform_str = build_transform_string(ctx)
          clip_id = ctx.clip_paths.last

          if transform_str
            @builder.open_group(transform: transform_str, clip_path_id: clip_id)
            emit_path(d, mode, ctx)
            @builder.close_group
          else
            emit_path(d, mode, ctx, clip_path_id: clip_id)
          end
        end

        def emit_path(d, mode, ctx, clip_path_id: nil)
          @builder.path(
            d: d, mode: mode,
            color: ctx.fill_color,
            stroke_color: ctx.stroke_color,
            stroke_width: ctx.stroke_width,
            line_cap: ctx.line_cap,
            line_join: ctx.line_join,
            dash: ctx.dash,
            clip_path_id: clip_path_id
          )
        end

        def build_transform_string(ctx)
          return nil if ctx.ctm.identity?

          decomp = ctx.ctm.decompose
          parts = []
          tx = decomp[:translate]
          parts << "translate(#{FormatNumber.call(tx[:x])} #{FormatNumber.call(tx[:y])})" if tx[:x].abs > 1e-6 || tx[:y].abs > 1e-6
          parts << "rotate(#{FormatNumber.call(decomp[:rotate])})" if decomp[:rotate].abs > 1e-6
          sc = decomp[:scale]
          if (sc[:x] - 1).abs > 1e-6 || (sc[:y] - 1).abs > 1e-6
            parts << "scale(#{FormatNumber.call(sc[:x])} #{FormatNumber.call(sc[:y])})"
          end
          parts.empty? ? nil : parts.join(" ")
        end
      end
    end
  end
end
