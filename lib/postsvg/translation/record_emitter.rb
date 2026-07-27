# frozen_string_literal: true

module Postsvg
  module Translation
    # Accumulator of Model::Operator instances that the PsRenderer
    # builds. Thin wrapper around an array; provides a uniform emit
    # surface so handlers don't all need to know how the program is
    # stored.
    class RecordEmitter
      attr_reader :records

      def initialize
        @records = []
      end

      def emit(record)
        @records << record
        self
      end

      def emit_many(records)
        records.each { |r| emit(r) }
        self
      end

      def length
        @records.length
      end

      def to_a
        @records.dup
      end
    end
  end
end
