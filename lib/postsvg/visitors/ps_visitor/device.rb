# frozen_string_literal: true

module Postsvg
  module Visitors
    class PsVisitor
      # Device / page operator handlers. In a single-page SVG render
      # these are largely no-ops; they exist so programs that end
      # with +showpage+ parse cleanly.
      module Device
        def visit_showpage(_op, _ctx)
          # No-op: SVG is single-page; the renderer finalises on close.
        end

        def visit_copypage(_op, _ctx); end

        def visit_nulldevice(_op, _ctx); end
      end
    end
  end
end
