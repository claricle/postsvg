# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      module Arithmetic
        BINARY_DEFAULT = { consumes: 2, produces: 1 }.freeze
        UNARY_DEFAULT = { consumes: 1, produces: 1 }.freeze

        class Add < Operator
          register_as "add", **BINARY_DEFAULT
          def self.from_operands(stack)
            b = stack.pop_number
            a = stack.pop_number
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end

        class Sub < Operator
          register_as "sub", **BINARY_DEFAULT
          def self.from_operands(stack)
            b = stack.pop_number
            a = stack.pop_number
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end

        class Mul < Operator
          register_as "mul", **BINARY_DEFAULT
          def self.from_operands(stack)
            b = stack.pop_number
            a = stack.pop_number
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end

        class Div < Operator
          register_as "div", **BINARY_DEFAULT
          def self.from_operands(stack)
            b = stack.pop_number
            a = stack.pop_number
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end

        class Idiv < Operator
          register_as "idiv", **BINARY_DEFAULT
          def self.from_operands(stack)
            b = stack.pop_number.to_i
            a = stack.pop_number.to_i
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end

        class Mod < Operator
          register_as "mod", **BINARY_DEFAULT
          def self.from_operands(stack)
            b = stack.pop_number.to_i
            a = stack.pop_number.to_i
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end

        class Neg < Operator
          register_as "neg", **UNARY_DEFAULT
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop_number)
          end
        end

        class Abs < Operator
          register_as "abs", **UNARY_DEFAULT
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop_number)
          end
        end

        class Ceiling < Operator
          register_as "ceiling", **UNARY_DEFAULT
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop_number)
          end
        end

        class Floor < Operator
          register_as "floor", **UNARY_DEFAULT
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop_number)
          end
        end

        class Round < Operator
          register_as "round", **UNARY_DEFAULT
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop_number)
          end
        end

        class Truncate < Operator
          register_as "truncate", **UNARY_DEFAULT
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop_number)
          end
        end

        class Sqrt < Operator
          register_as "sqrt", **UNARY_DEFAULT
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop_number)
          end
        end

        class Atan < Operator
          register_as "atan", **BINARY_DEFAULT
          def self.from_operands(stack)
            b = stack.pop_number
            a = stack.pop_number
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end

        class Cos < Operator
          register_as "cos", **UNARY_DEFAULT
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop_number)
          end
        end

        class Sin < Operator
          register_as "sin", **UNARY_DEFAULT
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop_number)
          end
        end

        class Ln < Operator
          register_as "ln", **UNARY_DEFAULT
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop_number)
          end
        end

        class Log < Operator
          register_as "log", **UNARY_DEFAULT
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop_number)
          end
        end

        class Exp < Operator
          register_as "exp", **BINARY_DEFAULT
          def self.from_operands(stack)
            b = stack.pop_number
            a = stack.pop_number
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end
      end
    end
  end
end
