# frozen_string_literal: true

module Postsvg
  module Translation
    module Handlers
      class GroupHandler
        extend Shared

        def self.call(element, context)
          context.emitter.emit(Model::Operators::GraphicsState::Gsave.new)
          emit_transform(element, context)
          emit_paint_setup(element, context)
          element.children.each do |child|
            Postsvg::Translation::PsRenderer::DEFAULT_REGISTRY.translate(child, context)
          end
          context.emitter.emit(Model::Operators::GraphicsState::Grestore.new)
        end
      end
    end
  end
end
