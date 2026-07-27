# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      module Stack
        class Pop < Operator
          register_as "pop", consumes: 1, produces: 0

          def self.from_operands(stack)
            stack.pop
            new
          end
        end

        class Exch < Operator
          register_as "exch", consumes: 2, produces: 2

          def self.from_operands(stack)
            stack.pop
            stack.pop
            new
          end
        end

        class Dup < Operator
          register_as "dup", consumes: 1, produces: 2

          def self.from_operands(stack)
            stack.pop
            new
          end
        end

        class Index < Operator
          register_as "index", consumes: 1, produces: 1
          attr_reader :index
          def initialize(index:)
            @index = index
            freeze
          end
          def self.from_operands(stack)
            new(index: stack.pop_number.to_i)
          end
        end

        class Roll < Operator
          register_as "roll", consumes: 2, produces: 0
          attr_reader :count, :positions
          def initialize(count:, positions:)
            @count = count
            @positions = positions
            freeze
          end
          def self.from_operands(stack)
            positions = stack.pop_number.to_i
            count = stack.pop_number.to_i
            new(count: count, positions: positions)
          end
        end

        class Clear < Operator
          register_as "clear", consumes: 0, produces: 0
        end

        class Count < Operator
          register_as "count", consumes: 0, produces: 1
        end
      end
    end
  end
end
