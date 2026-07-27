# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      module Container
        class Length < Operator
          register_as "length", consumes: 1, produces: 1
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
          def self.from_operands(stack)
            new(operand: stack.pop)
          end
        end

        class Get < Operator
          register_as "get", consumes: 2, produces: 1
          attr_reader :operand, :key
          def initialize(operand:, key:)
            @operand = operand
            @key = key
            freeze
          end
          def self.from_operands(stack)
            key = stack.pop
            coll = stack.pop
            new(operand: coll, key: key)
          end
        end

        class Put < Operator
          register_as "put", consumes: 3, produces: 0
          attr_reader :operand, :key, :value
          def initialize(operand:, key:, value:)
            @operand = operand
            @key = key
            @value = value
            freeze
          end
          def self.from_operands(stack)
            value = stack.pop
            key = stack.pop
            coll = stack.pop
            new(operand: coll, key: key, value: value)
          end
        end

        class Getinterval < Operator
          register_as "getinterval", consumes: 3, produces: 1
          attr_reader :operand, :start, :count
          def initialize(operand:, start:, count:)
            @operand = operand
            @start = start
            @count = count
            freeze
          end
          def self.from_operands(stack)
            count = stack.pop_number.to_i
            start = stack.pop_number.to_i
            coll = stack.pop
            new(operand: coll, start: start, count: count)
          end
        end

        class Putinterval < Operator
          register_as "putinterval", consumes: 3, produces: 0
          attr_reader :operand, :start, :source
          def initialize(operand:, start:, source:)
            @operand = operand
            @start = start
            @source = source
            freeze
          end
          def self.from_operands(stack)
            source = stack.pop
            start = stack.pop_number.to_i
            coll = stack.pop
            new(operand: coll, start: start, source: source)
          end
        end

        class Forall < Operator
          register_as "forall", consumes: 2, produces: 0
          attr_reader :collection, :body
          def initialize(collection:, body:)
            @collection = collection
            @body = body
            freeze
          end
          def self.from_operands(stack)
            body = stack.pop
            coll = stack.pop
            new(collection: coll, body: body)
          end
        end

        class Astore < Operator
          register_as "astore", consumes: 1, produces: 1
          attr_reader :array, :length
          def initialize(array:, length:)
            @array = array
            @length = length
            freeze
          end
          def self.from_operands(stack)
            arr = stack.pop
            length = stack.pop_number.to_i
            new(array: arr, length: length)
          end
        end

        class Search < Operator
          register_as "search", consumes: 2, produces: 1
          attr_reader :target, :pattern
          def initialize(target:, pattern:)
            @target = target
            @pattern = pattern
            freeze
          end
          def self.from_operands(stack)
            pattern = stack.pop
            target = stack.pop
            new(target: target, pattern: pattern)
          end
        end

        class Anchorsearch < Operator
          register_as "anchorsearch", consumes: 2, produces: 1
          attr_reader :target, :pattern
          def initialize(target:, pattern:)
            @target = target
            @pattern = pattern
            freeze
          end
          def self.from_operands(stack)
            pattern = stack.pop
            target = stack.pop
            new(target: target, pattern: pattern)
          end
        end

        class Token < Operator
          register_as "token", consumes: 1, produces: 1
          attr_reader :target
          def initialize(target:)
            @target = target
            freeze
          end
          def self.from_operands(stack)
            new(target: stack.pop)
          end
        end

        class String < Operator
          register_as "string", consumes: 1, produces: 1
          attr_reader :count
          def initialize(count:)
            @count = count
            freeze
          end
          def self.from_operands(stack)
            new(count: stack.pop_number.to_i)
          end
        end

        class Cvs < Operator
          register_as "cvs", consumes: 2, produces: 1
          attr_reader :value, :target
          def initialize(value:, target:)
            @value = value
            @target = target
            freeze
          end
          def self.from_operands(stack)
            target = stack.pop
            value = stack.pop
            new(value: value, target: target)
          end
        end
      end
    end
  end
end
