# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      module Color
        class Setgray < Operator
          register_as "setgray"
          attr_reader :gray
          def initialize(gray:)
            @gray = gray
            freeze
          end
          def self.from_operands(stack)
            new(gray: stack.pop_number)
          end
        end

        class Setrgbcolor < Operator
          register_as "setrgbcolor"
          attr_reader :red, :green, :blue
          def initialize(red:, green:, blue:)
            @red = red
            @green = green
            @blue = blue
            freeze
          end
          def self.from_operands(stack)
            blue = stack.pop_number
            green = stack.pop_number
            red = stack.pop_number
            new(red: red, green: green, blue: blue)
          end
        end

        class Setcmykcolor < Operator
          register_as "setcmykcolor"
          attr_reader :cyan, :magenta, :yellow, :key
          def initialize(cyan:, magenta:, yellow:, key:)
            @cyan = cyan
            @magenta = magenta
            @yellow = yellow
            @key = key
            freeze
          end
          def self.from_operands(stack)
            key = stack.pop_number
            yellow = stack.pop_number
            magenta = stack.pop_number
            cyan = stack.pop_number
            new(cyan: cyan, magenta: magenta, yellow: yellow, key: key)
          end
        end

        class Sethsbcolor < Operator
          register_as "sethsbcolor"
          attr_reader :hue, :saturation, :brightness
          def initialize(hue:, saturation:, brightness:)
            @hue = hue
            @saturation = saturation
            @brightness = brightness
            freeze
          end
          def self.from_operands(stack)
            brightness = stack.pop_number
            saturation = stack.pop_number
            hue = stack.pop_number
            new(hue: hue, saturation: saturation, brightness: brightness)
          end
        end
      end
    end
  end
end
