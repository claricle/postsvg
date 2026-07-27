# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      class DefsHandler
        # <defs> children are referenced; we don't paint them at the
        # point of definition. The ClipPathRegistry already indexed
        # clipPaths from the document; gradients / patterns are
        # future work.
        def self.call(_element, _context); end
      end
    end
  end
end
