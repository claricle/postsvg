# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Helpers shared across multiple visitor modules. Mixed into
      # PsVisitor so every module sees the same helpers without
      # re-defining them. DRY: previously +normalize_key+ existed
      # in both Dictionary and Container.
      module Common
        # Convert a key from any literal-typed value to the canonical
        # string form used in dictionary lookups.
        def normalize_key(key)
          case key
          when Model::Literals::Name then key.value
          when String then key.to_s.delete_prefix("/")
          else key.to_s
          end
        end

        # Coerce a runtime value to its underlying string content
        # (handles StringLiteral / HexLiteral / plain String).
        def string_value(node)
          case node
          when String then node
          when Model::Literals::StringLiteral then node.value
          when Model::Literals::HexLiteral then node.bytes
          end
        end

        # Resolve a value to a number, looking up names in the dict
        # stack when possible. Falls back to 0 for unknown values.
        def numeric_value(value)
          case value
          when Numeric then value
          when Model::Literals::Number then value.value
          when Model::Literals::Name
            entry = lookup_dict(value.value)
            entry ? numeric_value(entry) : 0
          when Model::Computed then 0
          else 0
          end
        end

        def lookup_dict(name)
          @dict_stack.reverse_each do |dict|
            return dict[name] if dict.key?(name)
          end
          nil
        end

        # PS truthiness: false, nil, and 0 are falsy. Everything else
        # (including the integer 1 and any non-zero Numeric, plus any
        # object) is truthy.
        def truthy?(value)
          return false if [false, nil].include?(value)

          return value != 0 if value.is_a?(Numeric)

          true
        end
      end
    end
  end
end
