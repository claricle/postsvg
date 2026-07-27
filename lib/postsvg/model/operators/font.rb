# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      # Font and text operators. These cover the subset of PLRM §5
      # needed to round-trip basic SVG `<text>` content; richer
      # font metrics (kerning, ligatures, glyph substitution) are
      # tracked in TODO.roadmap/20-font-and-text.md.
      module Font
        # Pushes a font dictionary onto the stack by name. +name+ is
        # the PostScript font name (e.g. "Helvetica"). The visitor
        # pushes a Font value object.
        class Findfont < Operator
          register_as "findfont", consumes: 1, produces: 1
          attr_reader :name
          def initialize(name:)
            @name = name
            freeze
          end
          def self.from_operands(stack)
            new(name: stack.pop)
          end
        end

        # Returns a new font dictionary scaled to the given size.
        class Scalefont < Operator
          register_as "scalefont", consumes: 2, produces: 1
          attr_reader :font, :size
          def initialize(font:, size:)
            @font = font
            @size = size
            freeze
          end
          def self.from_operands(stack)
            size = stack.pop_number
            font = stack.pop
            new(font: font, size: size)
          end
        end

        # Installs the font dictionary as the current font.
        class Setfont < Operator
          register_as "setfont", consumes: 1, produces: 0
          attr_reader :font
          def initialize(font:)
            @font = font
            freeze
          end
          def self.from_operands(stack)
            new(font: stack.pop)
          end
        end

        # Renders +text+ at the current point using the current font.
        class Show < Operator
          register_as "show", consumes: 1, produces: 0
          attr_reader :text
          def initialize(text:)
            @text = text
            freeze
          end
          def self.from_operands(stack)
            new(text: stack.pop)
          end
        end

        # Moves to (x, y) and renders +text+ (PLRM §5.5 xyshow
        # variant not implemented here).
        class Xyshow < Operator
          register_as "xyshow"
          attr_reader :text, :dx, :dy
          def initialize(text:, dx:, dy:)
            @text = text
            @dx = dx
            @dy = dy
            freeze
          end
          def self.from_operands(stack)
            dy = stack.pop
            dx = stack.pop
            text = stack.pop
            new(text: text, dx: dx, dy: dy)
          end
        end

        # Returns the width of +text+ under the current font (in
        # thousandths of a unit, divided by 1000). The visitor
        # pushes [x, y] onto the stack.
        class Stringwidth < Operator
          register_as "stringwidth"
          attr_reader :text
          def initialize(text:)
            @text = text
            freeze
          end
          def self.from_operands(stack)
            new(text: stack.pop)
          end
        end

        # Appends glyph outlines for +text+ to the current path
        # (PLRM charpath).
        class Charpath < Operator
          register_as "charpath"
          attr_reader :text, :stroke
          def initialize(text:, stroke:)
            @text = text
            @stroke = stroke
            freeze
          end
          def self.from_operands(stack)
            stroke = stack.pop
            text = stack.pop
            new(text: text, stroke: stroke)
          end
        end
      end
    end
  end
end
