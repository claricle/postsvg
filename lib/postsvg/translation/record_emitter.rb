# frozen_string_literal: true

module Postsvg
  module Translation
    # Accumulator of Model::Operator instances that the PsRenderer
    # builds. Thin wrapper around an array; provides a uniform emit
    # surface so handlers don't all need to know how the program is
    # stored.
    class RecordEmitter
      NUMBER_OPERANDS = lambda do |record|
        record.operand_values.map { |value| Model::Literals::Number.new(value) }
      end
      NO_OPERANDS = ->(_record) { [] }

      OPERAND_BUILDERS = {
        Model::Operators::Color::Setgray => NUMBER_OPERANDS,
        Model::Operators::Color::Setrgbcolor => NUMBER_OPERANDS,
        Model::Operators::GraphicsState::Setlinewidth => NUMBER_OPERANDS,
        Model::Operators::Path::Moveto => NUMBER_OPERANDS,
        Model::Operators::Path::Rmoveto => lambda do |record|
          [Model::Literals::Number.new(record.dx), Model::Literals::Number.new(record.dy)]
        end,
        Model::Operators::Path::Lineto => NUMBER_OPERANDS,
        Model::Operators::Path::Rlineto => NUMBER_OPERANDS,
        Model::Operators::Path::Curveto => NUMBER_OPERANDS,
        Model::Operators::Path::Rcurveto => NUMBER_OPERANDS,
        Model::Operators::Path::Arc => NUMBER_OPERANDS,
        Model::Operators::Path::Arcn => NUMBER_OPERANDS,
        Model::Operators::Transformations::Translate => NUMBER_OPERANDS,
        Model::Operators::Transformations::Scale => NUMBER_OPERANDS,
        Model::Operators::Font::Findfont => lambda do |record|
          [Model::Literals::Name.new(record.name, literal: true)]
        end,
        Model::Operators::Font::Scalefont => lambda do |record|
          [Model::Literals::Number.new(record.size)]
        end,
        Model::Operators::Font::Show => lambda do |record|
          [Model::Literals::StringLiteral.new(record.text)]
        end,
        Model::Operators::GraphicsState::Setlinecap => lambda do |record|
          [Model::Literals::Number.new(record.cap_code)]
        end,
        Model::Operators::GraphicsState::Setlinejoin => lambda do |record|
          [Model::Literals::Number.new(record.join_code)]
        end,
        Model::Operators::Transformations::Concat => lambda do |record|
          elements = record.matrix.map { |value| Model::Literals::Number.new(value) }
          [Model::Literals::ArrayLiteral.new(elements)]
        end,
      }.freeze

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
        @records.concat(OPERAND_BUILDERS.fetch(record.class, NO_OPERANDS).call(record))
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
