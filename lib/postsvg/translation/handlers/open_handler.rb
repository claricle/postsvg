# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      class OpenHandler
        # Unknown SVG element. Descend into children so known subtrees
        # still emit. Element base class guarantees a +children+
        # getter, so no capability check is needed.
        def self.call(element, context)
          element.children.each do |child|
            Postsvg::Translation::PsRenderer.default_registry.translate(child, context)
          end
        end
      end
    end
  end
end