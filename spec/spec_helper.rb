# frozen_string_literal: true

require "postsvg"
require "canon/rspec_matchers"

# Configure Canon for spec-friendly XML matching
Canon::Config.instance.xml.match.profile = :spec_friendly

# Test helpers shared by all example groups.
module PostsvgSpecHelpers
  def fixture_path(filename)
    File.join(__dir__, "fixtures", filename)
  end

  def read_fixture(filename)
    File.read(fixture_path(filename))
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include PostsvgSpecHelpers
end
