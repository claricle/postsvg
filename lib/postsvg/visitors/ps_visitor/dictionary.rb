# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Dictionary operator handlers (dict-specific only). Generic
      # collection operators (get / put / length / getinterval /
      # putinterval) live in the +Container+ module because they
      # dispatch on operand type at runtime.
      module Dictionary
        # The base PsVisitor class initializes +@dict_stack+ as a
        # single-element array (the global dictionary). Modules assume
        # it exists; they do not re-initialize.

        def visit_dict(_op, _ctx)
          @stack << {}
        end

        def visit_begin(_op, _ctx)
          value = @stack.pop
          @dict_stack << (value.is_a?(Hash) ? value : {})
        end

        def visit_end(_op, _ctx)
          @dict_stack.pop if @dict_stack.length > 1
        end

        def visit_def(op, _ctx)
          key = normalize_key(op.key)
          @dict_stack.last[key] = op.value
        end

        def visit_load(op, _ctx)
          key = normalize_key(op.key)
          @dict_stack.reverse_each do |dict|
            if dict.key?(key)
              @stack << dict[key]
              return
            end
          end
          raise UndefinedOperatorError, "no value bound to /#{key}"
        end

        def visit_store(op, _ctx)
          key = normalize_key(op.key)
          @dict_stack.reverse_each do |dict|
            if dict.key?(key)
              dict[key] = op.value
              return
            end
          end
          @dict_stack.last[key] = op.value
        end

        def visit_known(op, _ctx)
          key = normalize_key(op.key)
          dict = op.dict.is_a?(Hash) ? op.dict : {}
          @stack << dict.key?(key)
        end

        def visit_currentdict(_op, _ctx)
          @stack << @dict_stack.last
        end

        def visit_countdictstack(_op, _ctx)
          @stack << @dict_stack.length
        end

        def visit_dictstack(_op, _ctx)
          @stack << @dict_stack.dup
        end

        def visit_maxlength(op, _ctx)
          # PS dictionaries can grow dynamically; report current size.
          @stack << dict_size(op.operand)
        end

        def dict_size(operand)
          case operand
          when Hash then operand.length
          when Model::Literals::Dictionary then operand.entries.length
          else 0
          end
        end

        def dict_stack
          @dict_stack ||= [{}]
        end
        # normalize_key is provided by PsVisitor::Common.
      end
    end
  end
end
