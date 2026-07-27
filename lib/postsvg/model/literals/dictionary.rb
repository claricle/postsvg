# frozen_string_literal: true

module Postsvg
  module Model
    module Literals
      # Inline dictionary literal: +<< /Key (value) /Num 42 >>+.
      class Dictionary
        attr_reader :entries

        def initialize(entries = {})
          @entries = entries.dup.freeze
          freeze
        end

        def [](key) = @entries[key]
        def key?(key) = @entries.key?(key)
        def each(&block) = @entries.each(&block)

        def accept(visitor, ctx)
          visitor.visit_dictionary(self, ctx)
        end

        def ==(other)
          other.is_a?(Dictionary) && other.entries == @entries
        end
        alias eql? ==

        def hash
          @entries.hash
        end
      end
    end
  end
end
