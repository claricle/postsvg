# frozen_string_literal: true

module Postsvg
  # Source-reading layer: PS source text -> Model::Program.
  #
  # Lexer produces an array of Model::Token; AstBuilder walks tokens and
  # emits a typed Model::Program. Errors are raised as Postsvg::LexError
  # and Postsvg::SyntaxError respectively.
  module Source
    autoload :Lexer, "postsvg/source/lexer"
    autoload :AstBuilder, "postsvg/source/ast_builder"
    autoload :OperandStack, "postsvg/source/operand_stack"

    module_function

    # One-shot convenience: PS source -> Model::Program.
    def parse(source)
      AstBuilder.build(Lexer.tokenize(source))
    end
  end
end
