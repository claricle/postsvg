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
        # Operators built by the svg -> ps handlers carry their
        # operands as attributes; the serializer writes keywords only
        # and expects the operands as separate literal statements
        # ahead of the keyword (the shape the PS parse path produces).
        # Splice them in so the record stream round-trips.
        if record.is_a?(Model::Operator) &&
           record.class.public_method_defined?(:operand_values)
          record.operand_values.each do |v|
            @records << Model::Literals::Number.new(v)
          end
        end
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
