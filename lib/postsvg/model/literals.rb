# frozen_string_literal: true

module Postsvg
  module Model
    # PS literal value objects. Each is immutable, has value equality,
    # and knows how to (a) emit itself to a serializer and (b) be
    # visited by a renderer. They never carry executable behaviour —
    # they are data.
    module Literals
      autoload :Number, "postsvg/model/literals/number"
      autoload :Name, "postsvg/model/literals/name"
      autoload :StringLiteral, "postsvg/model/literals/string"
      autoload :HexLiteral, "postsvg/model/literals/hex"
      autoload :ArrayLiteral, "postsvg/model/literals/array"
      autoload :Procedure, "postsvg/model/literals/procedure"
      autoload :Dictionary, "postsvg/model/literals/dictionary"
    end
  end
end
