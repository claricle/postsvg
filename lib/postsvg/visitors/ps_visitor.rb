# frozen_string_literal: true

module Postsvg
  module Visitors
    # Walks a Model::Program and emits SVG via a SvgBuilder. Holds a
    # GraphicsStack (immutable snapshots), an operand stack (for
    # PostScript execution semantics that aren't expressed directly in
    # the operator node — e.g. user-defined procedures that call
    # arithmetic), and a current-path accumulator.
    #
    # Dispatch is per-category: a separate module mixed in for each
    # Model::Operators::* namespace. New operator categories = new
    # module + include line, not a switch edit.
    class PsVisitor
      MAX_RECURSION = 256

      autoload :Stack, "postsvg/visitors/ps_visitor/stack"
      autoload :Arithmetic, "postsvg/visitors/ps_visitor/arithmetic"
      autoload :Boolean, "postsvg/visitors/ps_visitor/boolean"
      autoload :Path, "postsvg/visitors/ps_visitor/path"
      autoload :Painting, "postsvg/visitors/ps_visitor/painting"
      autoload :Color, "postsvg/visitors/ps_visitor/color"
      autoload :GraphicsState, "postsvg/visitors/ps_visitor/graphics_state"
      autoload :Transformations, "postsvg/visitors/ps_visitor/transformations"
      autoload :Dictionary, "postsvg/visitors/ps_visitor/dictionary"
      autoload :ControlFlow, "postsvg/visitors/ps_visitor/control_flow"
      autoload :Device, "postsvg/visitors/ps_visitor/device"
      autoload :Font, "postsvg/visitors/ps_visitor/font"
      autoload :Container, "postsvg/visitors/ps_visitor/container"
      autoload :Common, "postsvg/visitors/ps_visitor/common"

      attr_reader :graphics, :stack, :path, :builder

      def initialize(builder:, graphics: GraphicsStack.new)
        @builder = builder
        @graphics = graphics
        @stack = [] # operand stack for execution semantics
        @path = PathState.new
        @dict_stack = [{}] # runtime dict stack (mirrors PLRM dict stack)
        @recursion_depth = 0
      end

      # Public entry: dispatch an operator node. Called from
      # Model::Operator#accept.
      def dispatch(method_name, operator, ctx)
        public_send(method_name, operator, ctx)
      end

      # Visit a Program body.
      def visit_program(program)
        program.body.each do |statement|
          statement.accept(self, nil)
        end
      end

      # Literal visits push themselves onto the operand stack.
      def visit_number(node, _ctx)
        @stack << node.value
      end

      def visit_name(node, _ctx)
        @stack << node
      end

      def visit_string_literal(node, _ctx)
        @stack << node.value
      end

      def visit_hex(node, _ctx)
        @stack << node
      end

      def visit_array(node, _ctx)
        @stack << node.elements
      end

      def visit_procedure(node, _ctx)
        @stack << node
      end

      def visit_dictionary(node, _ctx)
        @stack << node
      end

      # Default: unhandled operator becomes a comment.
      def visit_unknown(operator, _ctx)
        @builder.comment("unhandled operator: #{operator.keyword}")
      end

      # InvokeProcedure: descend into the body with the current state.
      def visit_invoke_procedure(invocation, _ctx)
        @recursion_depth += 1
        if @recursion_depth > MAX_RECURSION
          raise RecursionLimitError,
                "procedure #{invocation.name} exceeded recursion limit #{MAX_RECURSION}"
        end

        invocation.procedure.body.each { |node| node.accept(self, nil) }
      ensure
        @recursion_depth -= 1
      end

      # Helper for popping numbers off the operand stack.
      def pop_number
        v = @stack.pop
        numeric_value(v)
      end

      def pop_value
        @stack.pop || Model::Computed.new(operator_keyword: "(missing)")
      end

      # Path state: list of accumulated path commands and the current
      # pen position. Kept as a separate inner class so the visitor
      # body stays focused on dispatch + state mutations, not on path
      # geometry bookkeeping.
      class PathState
        attr_reader :commands, :current_x, :current_y

        def initialize
          @commands = []
          @current_x = 0.0
          @current_y = 0.0
        end

        def empty?
          @commands.empty?
        end

        def move_to(x, y)
          @commands << "M #{fmt(x)} #{fmt(y)}"
          @current_x = x.to_f
          @current_y = y.to_f
        end

        def move_to_rel(dx, dy)
          @commands << "m #{fmt(dx)} #{fmt(dy)}"
          @current_x += dx.to_f
          @current_y += dy.to_f
        end

        def line_to(x, y)
          @commands << "L #{fmt(x)} #{fmt(y)}"
          @current_x = x.to_f
          @current_y = y.to_f
        end

        def line_to_rel(dx, dy)
          @commands << "l #{fmt(dx)} #{fmt(dy)}"
          @current_x += dx.to_f
          @current_y += dy.to_f
        end

        def curve_to(x1, y1, x2, y2, x3, y3)
          @commands << "C #{fmt(x1)} #{fmt(y1)} #{fmt(x2)} #{fmt(y2)} #{fmt(x3)} #{fmt(y3)}"
          @current_x = x3.to_f
          @current_y = y3.to_f
        end

        def curve_to_rel(dx1, dy1, dx2, dy2, dx3, dy3)
          @commands << "c #{fmt(dx1)} #{fmt(dy1)} #{fmt(dx2)} #{fmt(dy2)} #{fmt(dx3)} #{fmt(dy3)}"
          @current_x += dx3.to_f
          @current_y += dy3.to_f
        end

        def arc_to(rx, ry, x_axis_rotation, large_arc, sweep, x, y)
          @commands << "A #{fmt(rx)} #{fmt(ry)} #{fmt(x_axis_rotation)} " \
                       "#{large_arc ? 1 : 0} #{sweep ? 1 : 0} #{fmt(x)} #{fmt(y)}"
          @current_x = x.to_f
          @current_y = y.to_f
        end

        def close
          @commands << "Z"
        end

        def reset
          @commands = []
          @current_x = 0.0
          @current_y = 0.0
        end

        def to_path_d
          @commands.join(" ")
        end

        def fmt(value)
          FormatNumber.call(value)
        end
      end

      include Stack
      include Arithmetic
      include Boolean
      include Path
      include Painting
      include Color
      include GraphicsState
      include Transformations
      include Dictionary
      include ControlFlow
      include Device
      include Font
      include Container
      include Common
    end
  end
end
