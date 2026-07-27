# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      # Dictionary-specific operators. Note that +get+, +put+,
      # +length+, +getinterval+, +putinterval+ live in the +Container+
      # module because they dispatch on operand type (string, array,
      # or dictionary) at runtime.
      module Dictionary
        class Dict < Operator
          register_as "dict", consumes: 1, produces: 1
          def self.from_operands(stack)
            stack.pop
            new
          end
        end

        class Begin < Operator
          register_as "begin", consumes: 1, produces: 0
          def self.from_operands(stack)
            stack.pop
            new
          end
        end

        class End < Operator
          register_as "end", consumes: 0, produces: 0
        end

        class Def < Operator
          register_as "def", consumes: 2, produces: 0
          attr_reader :key, :value
          def initialize(key:, value:)
            @key = key
            @value = value
            freeze
          end
          def self.from_operands(stack)
            value = stack.pop
            key = stack.pop
            new(key: key, value: value)
          end
        end

        class Load < Operator
          register_as "load", consumes: 1, produces: 1
          attr_reader :key
          def initialize(key:)
            @key = key
            freeze
          end
          def self.from_operands(stack)
            new(key: stack.pop)
          end
        end

        class Store < Operator
          register_as "store", consumes: 2, produces: 0
          attr_reader :key, :value
          def initialize(key:, value:)
            @key = key
            @value = value
            freeze
          end
          def self.from_operands(stack)
            value = stack.pop
            key = stack.pop
            new(key: key, value: value)
          end
        end

        class Known < Operator
          register_as "known", consumes: 2, produces: 1
          def self.from_operands(stack)
            key = stack.pop
            dict = stack.pop
            new(key: key, dict: dict)
          end
          attr_reader :key, :dict
          def initialize(key:, dict:)
            @key = key
            @dict = dict
            freeze
          end
        end

        class Currentdict < Operator
          register_as "currentdict", consumes: 0, produces: 1
        end

        class Countdictstack < Operator
          register_as "countdictstack", consumes: 0, produces: 1
        end

        class Dictstack < Operator
          register_as "dictstack", consumes: 1, produces: 1
          def self.from_operands(stack)
            stack.pop
            new
          end
        end

        class Maxlength < Operator
          register_as "maxlength", consumes: 1, produces: 1
          def self.from_operands(stack)
            new(operand: stack.pop)
          end
          attr_reader :operand
          def initialize(operand:)
            @operand = operand
            freeze
          end
        end
      end
    end
  end
end
