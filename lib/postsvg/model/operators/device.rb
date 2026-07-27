# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      module Device
        class Showpage < Operator
          register_as "showpage"
        end

        class Copypage < Operator
          register_as "copypage"
        end

        class Nulldevice < Operator
          register_as "nulldevice"
        end
      end
    end
  end
end
