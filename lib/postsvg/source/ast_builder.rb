# frozen_string_literal: true

module Postsvg
  module Source
    # Walks a token stream from the Lexer and produces a typed
    # Model::Program. Procedures, arrays, and dictionaries are kept as
    # Model literal nodes; operators are constructed via the
    # Model::Operators registry.
    class AstBuilder
      attr_reader :tokens, :stack, :body, :header, :dict_stack, :recursion_depth

      MAX_PROC_DEPTH = 64

      def initialize(tokens)
        @tokens = tokens
        @stack = OperandStack.new
        @body = []
        @dict_stack = [{}] # global dictionary
        @header = Model::Program::Header.new
        @recursion_depth = 0
      end

      def self.build(tokens)
        new(tokens).build
      end

      def build
        Model::Operators.load_all!
        consume_until(tokens.length)
        Model::Program.new(header: @header, body: @body)
      end

      private

      def consume_until(end_index, terminators: [], depth: 0)
        raise RecursionLimitError, "procedure depth exceeded #{MAX_PROC_DEPTH}" if depth > MAX_PROC_DEPTH

        i = 0
        collected = []
        while i < end_index
          token = tokens[i]
          break if terminators.include?(token&.type)

          i += consume_token(token, collected)
        end
        collected
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
      def consume_token(token, collected)
        case token.type
        when :number
          node = build_number(token)
          @stack.push(node)
          append_statement(node, collected)
          1
        when :string
          node = Model::Literals::StringLiteral.new(token.value)
          @stack.push(node)
          append_statement(node, collected)
          1
        when :hexstring
          node = Model::Literals::HexLiteral.new(token.value)
          @stack.push(node)
          append_statement(node, collected)
          1
        when :name
          node = Model::Literals::Name.new(token.value, literal: token.literal || false)
          @stack.push(node)
          append_statement(node, collected)
          1
        when :proc_open
          consume_procedure(after: token_position(token), collected: collected)
        when :array_open
          consume_array(after: token_position(token), collected: collected)
        when :dict_open
          consume_dict(after: token_position(token), collected: collected)
        when :dsc
          apply_dsc(token)
          1
        when :operator
          consume_operator(token, collected)
        else
          1
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity

      # Push a literal onto both the parse stack and the program body.
      # The body is what the visitor walks; the stack is what operator
      # factories pop from.
      def append_statement(node, collected)
        @body << node
        collected << node
      end

      def token_position(token)
        [token.line, token.column]
      end

      def build_number(token)
        raw = token.value
        value =
          if raw =~ /\A[-+]?\d+\z/
            raw.to_i
          elsif raw =~ /\A[-+]?\d+\.\d+\z/ || raw =~ /\A[-+]?(\.\d+|\d+\.)\z/
            raw.to_f
          elsif raw =~ /\A[-+]?(\d+\.?\d*|\.\d+)[eE][-+]?\d+\z/
            raw.to_f
          else
            raw.to_f
          end
        Model::Literals::Number.new(value)
      end

      # Consume a procedure body. Returns the number of tokens consumed
      # (including the closing brace). The Procedure value is pushed
      # onto the stack AND recorded as a statement on the program body
      # so the renderer can visit it standalone.
      def consume_procedure(after:, collected:)
        start_index = find_index(after)
        body_tokens, end_index = match_braces(start_index + 1)
        body_nodes = sub_build(body_tokens)
        procedure = Model::Literals::Procedure.new(body_nodes)
        @stack.push(procedure)
        append_statement(procedure, collected)
        end_index - start_index + 1
      end

      def consume_array(after:, collected:)
        start_index = find_index(after)
        body_tokens, end_index = match_until(start_index + 1, :array_close, :array_open)
        body_nodes = sub_build(body_tokens)
        array = Model::Literals::ArrayLiteral.new(body_nodes.select { |n| literal?(n) })
        @stack.push(array)
        append_statement(array, collected)
        end_index - start_index + 1
      end

      def consume_dict(after:, collected:)
        start_index = find_index(after)
        body_tokens, end_index = match_until(start_index + 1, :dict_close, :dict_open)
        entries = {}
        pending_key = nil
        sub_nodes = sub_build(body_tokens)
        sub_nodes.each do |node|
          if node.is_a?(Model::Literals::Name) && node.literal?
            pending_key = node.value
          elsif pending_key
            entries[pending_key] = node
            pending_key = nil
          end
        end
        dict = Model::Literals::Dictionary.new(entries)
        @stack.push(dict)
        collected << dict
        end_index - start_index + 1
      end

      def literal?(node)
        node.is_a?(Model::Literals::Number) ||
          node.is_a?(Model::Literals::Name) ||
          node.is_a?(Model::Literals::StringLiteral) ||
          node.is_a?(Model::Literals::HexLiteral) ||
          node.is_a?(Model::Literals::ArrayLiteral) ||
          node.is_a?(Model::Literals::Procedure) ||
          node.is_a?(Model::Literals::Dictionary)
      end

      def sub_build(sub_tokens)
        # Build a temporary AstBuilder over a sub-token-stream and
        # harvest its body. The temp builder shares no state with the
        # outer one.
        return [] if sub_tokens.empty?

        program = AstBuilder.new(sub_tokens).build
        program.body
      end

      def find_index(line_col)
        line, col = line_col
        tokens.each_with_index do |tok, idx|
          return idx if tok.line == line && tok.column == col
        end
        tokens.length
      end

      def match_braces(start_index)
        depth = 1
        i = start_index
        while i < tokens.length
          tok = tokens[i]
          if tok.type == :proc_open
            depth += 1
          elsif tok.type == :proc_close
            depth -= 1
            return [tokens[start_index...i], i] if depth.zero?
          end
          i += 1
        end
        raise SyntaxError, "unbalanced procedure braces"
      end

      def match_until(start_index, close_type, open_type)
        depth = 1
        i = start_index
        while i < tokens.length
          tok = tokens[i]
          if tok.type == open_type
            depth += 1
          elsif tok.type == close_type
            depth -= 1
            return [tokens[start_index...i], i] if depth.zero?
          end
          i += 1
        end
        raise SyntaxError, "unbalanced #{close_type}"
      end

      def consume_operator(token, collected)
        keyword = token.value

        # Resolve user-defined names to InvokeProcedure.
        if (proc_value = lookup_user_definition(keyword))
          if proc_value.is_a?(Model::Literals::Procedure)
            inv = Model::InvokeProcedure.new(name: keyword, procedure: proc_value)
            @body << inv
            collected << inv
            return 1
          end
        end

        operator_class = Model::Operators[keyword]
        unless operator_class
          unknown = Model::UnknownOperator.new(keyword: keyword)
          @body << unknown
          collected << unknown
          return 1
        end

        operator = operator_class.from_operands(@stack)
        return 1 if operator.nil?

        # Reflect the runtime stack shape: push a +Computed+ sentinel
        # for each value the operator would have produced at runtime.
        # This lets chained operators (findfont ... scalefont, add +
        # mul, etc.) parse cleanly even though their intermediate
        # results aren't yet known.
        operator.class.produces.to_i.times do
          @stack.push(Model::Computed.new(operator_keyword: keyword))
        end

        @body << operator
        collected << operator
        apply_side_effects(operator)
        1
      end

      # When a `def` operator is constructed, capture the binding into
      # the active dictionary so subsequent operator tokens can resolve
      # to InvokeProcedure.
      def apply_side_effects(operator)
        case operator
        when Model::Operators::Dictionary::Def
          @dict_stack.last[operator.key.to_s.sub(/\A\//, "")] = operator.value
        end
      end

      def lookup_user_definition(name)
        @dict_stack.reverse_each do |dict|
          return dict[name] if dict.key?(name)
        end
        nil
      end

      def apply_dsc(token)
        text = token.value.strip
        case text
        when /\ABoundingBox:\s*(-?[\d.eE+-]+)\s+(-?[\d.eE+-]+)\s+(-?[\d.eE+-]+)\s+(-?[\d.eE+-]+)\z/
          @header = @header.with(bounding_box: [
            ::Regexp.last_match(1).to_f, ::Regexp.last_match(2).to_f,
            ::Regexp.last_match(3).to_f, ::Regexp.last_match(4).to_f,
          ])
        when /\AHiResBoundingBox:\s*(-?[\d.eE+-]+)\s+(-?[\d.eE+-]+)\s+(-?[\d.eE+-]+)\s+(-?[\d.eE+-]+)\z/
          @header = @header.with(hires_bounding_box: [
            ::Regexp.last_match(1).to_f, ::Regexp.last_match(2).to_f,
            ::Regexp.last_match(3).to_f, ::Regexp.last_match(4).to_f,
          ])
        when /\ATitle:\s*(.+)\z/
          @header = @header.with(title: ::Regexp.last_match(1))
        when /\ACreator:\s*(.+)\z/
          @header = @header.with(creator: ::Regexp.last_match(1))
        when /\ACreationDate:\s*(.+)\z/
          @header = @header.with(creation_date: ::Regexp.last_match(1))
        when /\APages:\s*(\d+)\s+(\d+)\z/
          @header = @header.with(page_count: ::Regexp.last_match(1).to_i,
                                 pages: ::Regexp.last_match(2).to_i)
        when /\ALanguageLevel:\s*(\d+)\z/
          @header = @header.with(language_level: ::Regexp.last_match(1).to_i)
        when /\AEOF/, /\AEndComments/
          nil
        else
          @header = @header.with(custom: @header.custom.merge(text => true))
        end
      end
    end
  end
end
