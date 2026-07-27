# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Operators that operate on any collection (string, array,
      # dictionary). The visitor dispatches by +is_a?+ on the
      # operand at runtime.
      module Container
        def visit_length(op, _ctx)
          operand = op.operand
          value =
            case operand
            when String then operand.length
            when Array then operand.length
            when Hash then operand.length
            when Model::Literals::StringLiteral then operand.value.length
            when Model::Literals::ArrayLiteral then operand.elements.length
            when Model::Literals::Dictionary then operand.entries.length
            when Model::Literals::HexLiteral then operand.value.length / 2
            else 0
            end
          @stack << value
        end

        def visit_get(op, _ctx)
          operand = op.operand
          key = op.key
          value =
            case operand
            when Hash
              operand[normalize_key(key)]
            when Array
              operand[key.to_i]
            when String
              operand.getbyte(key.to_i)
            when Model::Literals::Dictionary
              operand.entries[normalize_key(key)]
            when Model::Literals::ArrayLiteral
              operand.elements[key.to_i]
            when Model::Literals::StringLiteral
              operand.value.getbyte(key.to_i)
            end
          @stack << value
        end

        def visit_put(_op, _ctx)
          # PS put mutates in place. Our value objects are immutable.
          # Marked as a comment in the output so the gap is visible.
          @builder.comment("put: in-place mutation not supported")
        end

        def visit_getinterval(op, _ctx)
          @stack << case op.operand
                    when String
                      op.operand[op.start, op.count]
                    when Array
                      op.operand[op.start, op.count]
                    when Model::Literals::StringLiteral
                      op.operand.value[op.start, op.count]
                    when Model::Literals::ArrayLiteral
                      op.operand.elements[op.start, op.count]
                    else
                      ""
                    end
        end

        def visit_putinterval(_op, _ctx)
          @builder.comment("putinterval: in-place mutation not supported")
        end

        def visit_forall(op, _ctx)
          return unless op.body.is_a?(Model::Literals::Procedure)

          case op.collection
          when Array
            op.collection.each do |item|
              @stack << item
              op.body.body.each { |node| node.accept(self, nil) }
            end
          when Hash
            op.collection.each do |key, value|
              @stack << value
              @stack << key
              op.body.body.each { |node| node.accept(self, nil) }
            end
          when String
            op.collection.each_byte do |byte|
              @stack << byte
              op.body.body.each { |node| node.accept(self, nil) }
            end
          end
        end

        def visit_astore(op, _ctx)
          # astore pops N items and builds an array. The parser
          # already gave us the array via from_operands; just push
          # it back. The original semantics (`arr astore` arr is on
          # bottom, n items on top) are preserved.
          @stack << (op.array.is_a?(Array) ? op.array : [])
        end

        def visit_search(op, _ctx)
          haystack = string_value(op.target)
          needle = string_value(op.pattern)
          if haystack && needle && (idx = haystack.index(needle))
            post = haystack[(idx + needle.length)..]
            @stack << post
            @stack << needle
            @stack << haystack[0, idx]
            @stack << true
          else
            @stack << haystack
            @stack << false
          end
        end

        def visit_anchorsearch(op, _ctx)
          haystack = string_value(op.target)
          needle = string_value(op.pattern)
          if haystack && needle && haystack.start_with?(needle)
            @stack << haystack[needle.length..]
            @stack << needle
            @stack << true
          else
            @stack << haystack
            @stack << false
          end
        end

        def visit_token(op, _ctx)
          text = string_value(op.target)
          return @stack << false unless text

          # PS token splits on whitespace and parses the next token.
          if (match = text.match(/\A\s*(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)/))
            @stack << match[1].to_f
            @stack << text[match[0].length..]
            @stack << true
          else
            @stack << false
          end
        end

        def visit_string(op, _ctx)
          @stack << ("\0" * op.count.to_i)
        end

        def visit_cvs(op, _ctx)
          text =
            case op.value
            when Numeric then op.value.to_s
            when String then op.value
            when Model::Literals::StringLiteral then op.value.value
            when Model::Literals::Name then op.value.value
            else op.value.to_s
            end
          @stack << text
        end
        # normalize_key and string_value are provided by PsVisitor::Common.
      end
    end
  end
end
