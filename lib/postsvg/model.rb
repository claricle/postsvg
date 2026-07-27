# frozen_string_literal: true

module Postsvg
  # PS domain model. Every value object that participates in the AST
  # or in round-trip is a Model::* class. The lexer emits Model::Token;
  # the parser emits Model::Program; the renderer / serializer consume
  # Model::Program.
  module Model
    autoload :Token, "postsvg/model/token"
    autoload :Program, "postsvg/model/program"
    autoload :Literals, "postsvg/model/literals"
    autoload :Operator, "postsvg/model/operator"
    autoload :UnknownOperator, "postsvg/model/operator"
    autoload :InvokeProcedure, "postsvg/model/operator"
    autoload :Operators, "postsvg/model/operators"
  end
end
