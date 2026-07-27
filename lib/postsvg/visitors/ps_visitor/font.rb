# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Font and text operator handlers. Each pops from the RUNTIME
      # stack (not the AST) so chained font setup works:
      #
      #   /Helvetica findfont 18 scalefont setfont
      #
      # pushes a FontRef after findfont, scales it after scalefont,
      # installs it after setfont.
      module Font
        # Tracks the current font for later +show+. The visitor
        # pushes FontRef value objects onto the stack.
        FontRef = Struct.new(:name, :size, keyword_init: true) do
          def initialize(name:, size:)
            super
            freeze
          end
        end

        def visit_findfont(op, _ctx)
          name =
            case op.name
            when Model::Literals::Name then op.name.value
            when Model::Literals::StringLiteral then op.name.value
            else op.name.to_s
            end
          @stack << FontRef.new(name: name, size: nil)
        end

        def visit_scalefont(op, _ctx)
          size = op.size.to_i || op.size.to_f
          font = @stack.pop
          base = font.is_a?(FontRef) ? font : FontRef.new(name: "Helvetica", size: nil)
          @stack << FontRef.new(name: base.name, size: size.to_f)
        end

        def visit_setfont(_op, _ctx)
          font = @stack.pop
          ref = font.is_a?(FontRef) ? font : FontRef.new(name: "Helvetica", size: 12.0)
          @graphics.update(font_name: ref.name || "Helvetica",
                           font_size: ref.size || 12.0)
        end

        def visit_show(_op, _ctx)
          text = @stack.pop
          text_str =
            case text
            when Model::Literals::StringLiteral then text.value
            when String then text
            else text.to_s
            end
          pos = @graphics.current.last_text_position
          return unless pos

          ctm = @graphics.current.ctm
          screen_pos = ctm.apply_point(pos[:x], pos[:y])
          color = @graphics.current.fill_color
          # SVG y is inverted relative to PS — the Y-flip wrapper
          # group already flips the whole body, so we emit a
          # scale(1 -1) per <text> to undo the flip for text only.
          @builder.text(
            content: text_str,
            x: screen_pos[:x],
            y: -screen_pos[:y],
            font_family: @graphics.current.font_name,
            font_size: @graphics.current.font_size,
            color: color || Postsvg::Color::BLACK,
            transform: "scale(1 -1)",
          )
          @path.reset
          @graphics.update(last_text_position: nil)
        end

        def visit_xyshow(_op, _ctx)
          @builder.comment("xyshow: not yet implemented")
        end

        def visit_stringwidth(_op, _ctx)
          # Without real font metrics, push zero advance.
          @stack << 0
          @stack << 0
        end

        def visit_charpath(_op, _ctx)
          @builder.comment("charpath: requires font metrics")
        end
      end
    end
  end
end
