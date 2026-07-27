# frozen_string_literal: true

module Postsvg
  module Svg
    # Parsed SVG transform attribute. Produces a list of
    # Postsvg::Matrix instances that, multiplied in order, give the
    # composite CTM for the element.
    class TransformList
      attr_reader :matrices

      def initialize(matrices = [])
        @matrices = matrices.freeze
        freeze
      end

      def empty?
        @matrices.empty?
      end

      def composite
        return Matrix.new if @matrices.empty?

        @matrices.reduce(Matrix.new) { |acc, m| acc.multiply(m) }
      end

      def self.parse(text)
        return new if text.nil? || text.strip.empty?

        matrices = []
        text.scan(/(\w+)\s*\(([^)]*)\)/).each do |name, args|
          nums = args.split(/[\s,]+/).map(&:to_f)
          case name
          when "matrix"
            next unless nums.length == 6

            matrices << Matrix.new(a: nums[0], b: nums[1], c: nums[2],
                                   d: nums[3], e: nums[4], f: nums[5])
          when "translate"
            tx = nums[0] || 0
            ty = nums[1] || 0
            matrices << Matrix.new(e: tx, f: ty)
          when "scale"
            sx = nums[0] || 1
            sy = nums.length > 1 ? nums[1] : sx
            matrices << Matrix.new(a: sx, d: sy)
          when "rotate"
            angle = nums[0] || 0
            matrices << Matrix.new.rotate(angle)
          when "skewX"
            matrices << Matrix.new.skew_x(nums[0] || 0)
          when "skewY"
            matrices << Matrix.new.skew_y(nums[0] || 0)
          end
        end
        new(matrices)
      end
    end
  end
end
