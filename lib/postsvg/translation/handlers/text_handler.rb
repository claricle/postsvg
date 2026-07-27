# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      # SVG `<text>`. Emits a complete PS text sequence:
      #
      #   /<font-family> findfont
      #   <font-size> scalefont
      #   setfont
      #   <x> <y> moveto
      #   (text) show
      #
      # Real font metrics (kerning, ligatures, glyph substitution) are
      # tracked in TODO.roadmap/20-font-and-text.md. The shape of the
      # emitted sequence matches PLRM §5 so PS interpreters that DO
      # have the named font will render the text correctly.
      class TextHandler
        extend Shared

        def self.call(element, context)
          context.emitter.emit(Model::Operators::GraphicsState::Gsave.new)
          emit_transform(element, context)
          emit_fill(element, context) if element.fill&.color?

          font_name = font_name_value(element)
          context.emitter.emit(Model::Operators::Font::Findfont.new(name: font_name))
          context.emitter.emit(Model::Operators::Font::Scalefont.new(
                                 font: Model::Computed.new(operator_keyword: "findfont"),
                                 size: element.font_size,
                               ))
          context.emitter.emit(Model::Operators::Font::Setfont.new(
                                 font: Model::Computed.new(operator_keyword: "scalefont"),
                               ))
          context.emitter.emit(Model::Operators::Path::Moveto.new(x: element.x,
                                                                  y: element.y))
          context.emitter.emit(Model::Operators::Font::Show.new(text: element.content.to_s))

          context.emitter.emit(Model::Operators::GraphicsState::Grestore.new)
          expand_bbox(context,
                      element.x, element.y,
                      element.x + (element.content.to_s.length * element.font_size / 2.0),
                      element.y + element.font_size)
        end

        # Strip quotes; SVG allows comma-separated fallback list,
        # take the first family.
        def self.font_name_value(element)
          raw = element.font_family.to_s
          raw = raw.gsub(/["']/, "")
          raw.split(",").first.to_s.strip
        end
        private_class_method :font_name_value
      end
    end
  end
end
