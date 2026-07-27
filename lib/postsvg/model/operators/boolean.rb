# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      module Boolean
        # PS boolean literals. They look like operator tokens but
        # push constant Boolean values. Modeled as zero-arity
        # operators so the parser/registry handle them naturally.
        class True < Operator
          register_as "true", consumes: 0, produces: 1
        end

        class False < Operator
          register_as "false", consumes: 0, produces: 1
        end

        class Eq < Operator
          register_as "eq"
          def self.from_operands(stack)
            b = stack.pop
            a = stack.pop
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end

        class Ne < Operator
          register_as "ne"
          def self.from_operands(stack)
            b = stack.pop
            a = stack.pop
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end

        class Gt < Operator
          register_as "gt"
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

        class Ge < Operator
          register_as "ge"
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

        class Lt < Operator
          register_as "lt"
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

        class Le < Operator
          register_as "le"
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

        class And < Operator
          register_as "and"
          def self.from_operands(stack)
            b = stack.pop
            a = stack.pop
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end

        class Or < Operator
          register_as "or"
          def self.from_operands(stack)
            b = stack.pop
            a = stack.pop
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end

        class Xor < Operator
          register_as "xor"
          def self.from_operands(stack)
            b = stack.pop
            a = stack.pop
            new(operand_a: a, operand_b: b)
          end
          attr_reader :operand_a, :operand_b
          def initialize(operand_a:, operand_b:)
            @operand_a = operand_a
            @operand_b = operand_b
            freeze
          end
        end

        class Not < Operator
          register_as "not"
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop)
          end
        end

        class Bitshift < Operator
          register_as "bitshift"
          def self.from_operands(stack)
            shift = stack.pop_number.to_i
            value = stack.pop_number.to_i
            new(operand: value, shift: shift)
          end
          attr_reader :operand, :shift
          def initialize(operand:, shift:)
            @operand = operand
            @shift = shift
            freeze
          end
        end
      end
    end
  end
end
