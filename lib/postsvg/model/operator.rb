# frozen_string_literal: true

module Postsvg
  module Model
    # Common base for every PS operator. Subclasses live under
    # Model::Operators::* grouped by PLRM chapter.
    #
    # Each operator declares:
    # - +keyword+ (the PS source token, e.g. "moveto")
    # - typed operand fields via +attr_reader+
    # - +self.from_operands(stack)+ that pops operands and returns a new
    #   frozen instance
    # - +self.visit_name+ (defaults to the keyword)
    # - +self.consumes+ / +self.produces+ (stack-arity, for parser
    #   placeholders)
    #
    # The visitor calls +operator.accept(visitor, ctx)+ which routes to
    # +visitor.visit_<visit_name>(operator, ctx)+ via +public_send+.
    class Operator
      class << self
        # Register this class under +keyword+ in the global Registry.
        # Called at the bottom of each subclass definition.
        def register_as(keyword, consumes: 0, produces: 0)
          Operators.register(keyword, self)
          define_method(:keyword) { keyword }
          define_method(:visit_name) { keyword }
          @consumes = consumes
          @produces = produces
        end

        attr_reader :consumes, :produces

        # Default: a no-op factory that pops nothing. Subclasses
        # override to consume operands off the parse stack.
        def from_operands(_stack)
          new
        end
      end

      def accept(visitor, ctx)
        visitor.dispatch(:"visit_#{visit_name}", self, ctx)
      end

      def operator? = true
    end

    # Sentinel value the parser pushes onto the operand stack when an
    # operator's runtime result is unknown at parse time (e.g. the
    # output of +findfont+, +add+, +dup+). Carries no semantic value;
    # its purpose is to keep the parse-stack shape in sync with the
    # runtime stack so chained operators parse cleanly.
    class Computed < ::Struct.new(:operator_keyword, keyword_init: true)
      def to_s
        "<computed:#{operator_keyword}>"
      end
    end
  end
end
