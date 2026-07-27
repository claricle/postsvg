# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      module GraphicsState
        class Gsave < Operator
          register_as "gsave"
        end

        class Grestore < Operator
          register_as "grestore"
        end

        class Grestoreall < Operator
          register_as "grestoreall"
        end

        class Setlinewidth < Operator
          register_as "setlinewidth"
          attr_reader :width
          def initialize(width:)
            @width = width
            freeze
          end
          def self.from_operands(stack)
            new(width: stack.pop_number)
          end
        end

        class Setlinecap < Operator
          register_as "setlinecap"
          attr_reader :cap_code
          def initialize(cap_code:)
            @cap_code = cap_code.to_i
            freeze
          end
          def self.from_operands(stack)
            new(cap_code: stack.pop_number.to_i)
          end
        end

        class Setlinejoin < Operator
          register_as "setlinejoin"
          attr_reader :join_code
          def initialize(join_code:)
            @join_code = join_code.to_i
            freeze
          end
          def self.from_operands(stack)
            new(join_code: stack.pop_number.to_i)
          end
        end

        class Setmiterlimit < Operator
          register_as "setmiterlimit"
          attr_reader :limit
          def initialize(limit:)
            @limit = limit
            freeze
          end
          def self.from_operands(stack)
            new(limit: stack.pop_number)
          end
        end

        class Setdash < Operator
          register_as "setdash"
          attr_reader :pattern, :offset
          def initialize(pattern:, offset:)
            @pattern = pattern
            @offset = offset
            freeze
          end
          def self.from_operands(stack)
            offset = stack.pop_number
            pattern = stack.pop
            new(pattern: pattern, offset: offset)
          end
        end
      end
    end
  end
end
