# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      module Transformations
        class Translate < Operator
          register_as "translate"
          attr_reader :tx, :ty
          def initialize(tx:, ty:)
            @tx = tx
            @ty = ty
            freeze
          end
          def self.from_operands(stack)
            ty = stack.pop_number
            tx = stack.pop_number
            new(tx: tx, ty: ty)
          end
        end

        class Scale < Operator
          register_as "scale"
          attr_reader :sx, :sy
          def initialize(sx:, sy:)
            @sx = sx
            @sy = sy
            freeze
          end
          def self.from_operands(stack)
            sy = stack.pop_number
            sx = stack.pop_number
            new(sx: sx, sy: sy)
          end
        end

        class Rotate < Operator
          register_as "rotate"
          attr_reader :angle
          def initialize(angle:)
            @angle = angle
            freeze
          end
          def self.from_operands(stack)
            new(angle: stack.pop_number)
          end
        end

        class Concat < Operator
          register_as "concat"
          attr_reader :matrix
          def initialize(matrix:)
            @matrix = matrix
            freeze
          end
          def self.from_operands(stack)
            new(matrix: stack.pop)
          end
        end

        class Matrix < Operator
          register_as "matrix"
        end

        class Currentmatrix < Operator
          register_as "currentmatrix"
        end

        class Setmatrix < Operator
          register_as "setmatrix"
          attr_reader :matrix
          def initialize(matrix:)
            @matrix = matrix
            freeze
          end
          def self.from_operands(stack)
            new(matrix: stack.pop)
          end
        end

        class Transform < Operator
          register_as "transform"
          def self.from_operands(stack); end
        end

        class Dtransform < Operator
          register_as "dtransform"
          def self.from_operands(stack); end
        end

        class Itransform < Operator
          register_as "itransform"
          def self.from_operands(stack); end
        end

        class Idtransform < Operator
          register_as "idtransform"
          def self.from_operands(stack); end
        end
      end
    end
  end
end
