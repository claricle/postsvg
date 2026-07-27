# frozen_string_literal: true

require_relative "lib/postsvg/version"

Gem::Specification.new do |spec|
  spec.name = "postsvg"
  spec.version = Postsvg::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Pure Ruby bidirectional PS/EPS <-> SVG converter"
  spec.description = <<~HEREDOC
    Postsvg is a pure-Ruby transformer between PostScript (PS) /
    Encapsulated PostScript (EPS) and Scalable Vector Graphics (SVG).
    Both directions are implemented: PS/EPS -> SVG and SVG -> PS/EPS.
    No external tools (Ghostscript, Inkscape) are required.
  HEREDOC

  spec.homepage = "https://github.com/claricle/postsvg"
  spec.license = "BSD-2-Clause"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/claricle/postsvg"
  spec.metadata["changelog_uri"] = "https://github.com/claricle/postsvg/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/claricle/postsvg/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"
  spec.add_dependency "parslet"
  spec.add_dependency "postscript", "~> 0.1"
  spec.add_dependency "thor"
end
