# frozen_string_literal: true

module Postsvg
  module Model
    module Literals
      # Procedure body: +{ ... }+. Carries the inner token stream as a
      # list of literal/operator nodes. Procedures are not executed by
      # the parser; the renderer descends into them on InvokeProcedure.
      class Procedure
        include Enumerable

        attr_reader :body

        def initialize(body = [])
          @body = body.freeze
          freeze
        end

        def each(&block)
          @body.each(&block)
        end

        def length = @body.length
        def empty? = @body.empty?

        def accept(visitor, ctx)
          visitor.visit_procedure(self, ctx)
        end

        def ==(other)
          other.is_a?(Procedure) && other.body == @body
        end
        alias eql? ==

        def hash
          @body.hash
        end
      end
    end
  end
end
