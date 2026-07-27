# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      class ClipPathHandler
        # clipPath definitions are read at parse time into
        # Svg::ClipPathRegistry. Nothing to emit here.
        def self.call(_element, _context); end
      end
    end
  end
end
