# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      module Path
        class Newpath < Operator
          register_as "newpath"
        end

        class Moveto < Operator
          register_as "moveto"
          attr_reader :x, :y
          def initialize(x:, y:)
            @x = x
            @y = y
            freeze
          end
          def self.from_operands(stack)
            y = stack.pop_number
            x = stack.pop_number
            new(x: x, y: y)
          end
        end

        class Rmoveto < Operator
          register_as "rmoveto"
          attr_reader :dx, :dy
          def initialize(dx:, dy:)
            @dx = dx
            @dy = dy
            freeze
          end
          def self.from_operands(stack)
            dy = stack.pop_number
            dx = stack.pop_number
            new(dx: dx, dy: dy)
          end
        end

        class Lineto < Operator
          register_as "lineto"
          attr_reader :x, :y
          def initialize(x:, y:)
            @x = x
            @y = y
            freeze
          end
          def self.from_operands(stack)
            y = stack.pop_number
            x = stack.pop_number
            new(x: x, y: y)
          end
        end

        class Rlineto < Operator
          register_as "rlineto"
          attr_reader :dx, :dy
          def initialize(dx:, dy:)
            @dx = dx
            @dy = dy
            freeze
          end
          def self.from_operands(stack)
            dy = stack.pop_number
            dx = stack.pop_number
            new(dx: dx, dy: dy)
          end
        end

        class Curveto < Operator
          register_as "curveto"
          attr_reader :x1, :y1, :x2, :y2, :x3, :y3
          def initialize(x1:, y1:, x2:, y2:, x3:, y3:)
            @x1 = x1
            @y1 = y1
            @x2 = x2
            @y2 = y2
            @x3 = x3
            @y3 = y3
            freeze
          end
          def self.from_operands(stack)
            y3 = stack.pop_number
            x3 = stack.pop_number
            y2 = stack.pop_number
            x2 = stack.pop_number
            y1 = stack.pop_number
            x1 = stack.pop_number
            new(x1: x1, y1: y1, x2: x2, y2: y2, x3: x3, y3: y3)
          end
        end

        class Rcurveto < Operator
          register_as "rcurveto"
          attr_reader :dx1, :dy1, :dx2, :dy2, :dx3, :dy3
          def initialize(dx1:, dy1:, dx2:, dy2:, dx3:, dy3:)
            @dx1 = dx1
            @dy1 = dy1
            @dx2 = dx2
            @dy2 = dy2
            @dx3 = dx3
            @dy3 = dy3
            freeze
          end
          def self.from_operands(stack)
            dy3 = stack.pop_number
            dx3 = stack.pop_number
            dy2 = stack.pop_number
            dx2 = stack.pop_number
            dy1 = stack.pop_number
            dx1 = stack.pop_number
            new(dx1: dx1, dy1: dy1, dx2: dx2, dy2: dy2, dx3: dx3, dy3: dy3)
          end
        end

        class Arc < Operator
          register_as "arc"
          attr_reader :x, :y, :radius, :angle1, :angle2
          def initialize(x:, y:, radius:, angle1:, angle2:)
            @x = x
            @y = y
            @radius = radius
            @angle1 = angle1
            @angle2 = angle2
            freeze
          end
          def self.from_operands(stack)
            angle2 = stack.pop_number
            angle1 = stack.pop_number
            radius = stack.pop_number
            y = stack.pop_number
            x = stack.pop_number
            new(x: x, y: y, radius: radius, angle1: angle1, angle2: angle2)
          end
        end

        class Arcn < Operator
          register_as "arcn"
          attr_reader :x, :y, :radius, :angle1, :angle2
          def initialize(x:, y:, radius:, angle1:, angle2:)
            @x = x
            @y = y
            @radius = radius
            @angle1 = angle1
            @angle2 = angle2
            freeze
          end
          def self.from_operands(stack)
            angle2 = stack.pop_number
            angle1 = stack.pop_number
            radius = stack.pop_number
            y = stack.pop_number
            x = stack.pop_number
            new(x: x, y: y, radius: radius, angle1: angle1, angle2: angle2)
          end
        end

        class Closepath < Operator
          register_as "closepath"
        end

        class Currentpoint < Operator
          register_as "currentpoint"
        end
      end
    end
  end
end
