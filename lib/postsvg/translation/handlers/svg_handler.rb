# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      class SvgHandler
        extend Shared

        def self.call(element, context)
          # SVG root: descend into children. Header / viewBox are
          # captured by the PsRenderer; no records needed here.
          descend(element, context)
        end

        # Walks an element's +children+ using the default registry.
        # Element base class guarantees the +children+ getter.
        def self.descend(element, context)
          element.children.each do |child|
            Postsvg::Translation::PsRenderer.default_registry.translate(child,
                                                                        context)
          end
        end
      end
    end
  end
end
