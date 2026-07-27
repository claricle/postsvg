# frozen_string_literal: true

module Postsvg
  # Visitor namespace. Each direction (PS->SVG, SVG->PS, future PS->PS)
  # has its own visitor subclass that consumes Model nodes.
  module Visitors
    autoload :PsVisitor, "postsvg/visitors/ps_visitor"
  end
end
