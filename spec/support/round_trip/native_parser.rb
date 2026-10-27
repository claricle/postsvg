# frozen_string_literal: true

module RoundTrip
  # Selects the upstream native engine explicitly, never the Ruby default.
  module NativeParser
    def self.unavailability_reason
      unless Postscript::Source.const_defined?(:NativeEngine)
        gem = Gem.loaded_specs.fetch("postscript")
        return "postscript #{gem.version} at #{gem.full_gem_path} lacks " \
               "postscript/source/native_engine.rb and Source.parse(engine: :native)"
      end

      call("")
      nil
    rescue Postscript::NativeEngineUnavailable => e
      e.message
    end

    def self.call(source)
      Postscript::Source.parse(source, engine: :native)
    end
  end
end
