# frozen_string_literal: true

module Postsvg
  module Model
    module Operators
      module Painting
        class Stroke < Operator
          register_as "stroke", consumes: 0, produces: 0
        end

        class Fill < Operator
          register_as "fill", consumes: 0, produces: 0
        end

        class Eofill < Operator
          register_as "eofill", consumes: 0, produces: 0
        end

        class Clip < Operator
          register_as "clip", consumes: 0, produces: 0
        end

        class Eoclip < Operator
          register_as "eoclip", consumes: 0, produces: 0
        end
      end
    end
  end
end
