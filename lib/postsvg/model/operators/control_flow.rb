# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      module ControlFlow
        class If < Operator
          register_as "if"
          attr_reader :condition, :body
          def initialize(condition:, body:)
            @condition = condition
            @body = body
            freeze
          end
          def self.from_operands(stack)
            body = stack.pop
            condition = stack.pop
            new(condition: condition, body: body)
          end
        end

        class Ifelse < Operator
          register_as "ifelse"
          attr_reader :condition, :if_body, :else_body
          def initialize(condition:, if_body:, else_body:)
            @condition = condition
            @if_body = if_body
            @else_body = else_body
            freeze
          end
          def self.from_operands(stack)
            else_body = stack.pop
            if_body = stack.pop
            condition = stack.pop
            new(condition: condition, if_body: if_body, else_body: else_body)
          end
        end

        class Repeat < Operator
          register_as "repeat"
          attr_reader :count, :body
          def initialize(count:, body:)
            @count = count
            @body = body
            freeze
          end
          def self.from_operands(stack)
            body = stack.pop
            count = stack.pop_number.to_i
            new(count: count, body: body)
          end
        end

        class Loop < Operator
          register_as "loop"
          attr_reader :body
          def initialize(body:)
            @body = body
            freeze
          end
          def self.from_operands(stack)
            new(body: stack.pop)
          end
        end

        class For < Operator
          register_as "for"
          attr_reader :initial, :increment, :limit, :body
          def initialize(initial:, increment:, limit:, body:)
            @initial = initial
            @increment = increment
            @limit = limit
            @body = body
            freeze
          end
          def self.from_operands(stack)
            body = stack.pop
            limit = stack.pop_number
            increment = stack.pop_number
            initial = stack.pop_number
            new(initial: initial, increment: increment, limit: limit, body: body)
          end
        end

        class Exit < Operator
          register_as "exit"
        end

        class Quit < Operator
          register_as "quit"
        end

        class Exec < Operator
          register_as "exec"
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop)
          end
        end

        class Stopped < Operator
          register_as "stopped"
          attr_reader :body
          def initialize(body:)
            @body = body
            freeze
          end
          def self.from_operands(stack)
            new(body: stack.pop)
          end
        end
      end
    end
  end
end
