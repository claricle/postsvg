# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "yaml"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :round_trip do
  desc "Regenerate pinned PostScript output for the round-trip corpus"
  task :regenerate_goldens do
    require "postsvg"

    root = File.expand_path("spec/fixtures/round_trip", __dir__)
    manifest = YAML.safe_load_file(File.join(root, "manifest.yml"))

    manifest.fetch("fixtures").each do |entry|
      svg_path = File.join(root, entry.fetch("file"))
      golden_path = svg_path.sub(/\.svg\z/, ".ps.golden")
      File.binwrite(golden_path, Postsvg.to_ps(File.read(svg_path)))
    end
  end
end

# Link checking tasks
namespace :check do
  desc "Check internal documentation links only (recommended for CI)"
  task :links do
    puts "Checking internal documentation links..."
    puts "(External URLs are skipped to avoid anti-bot measures)"
    puts

    # Check if lychee is installed
    unless system("which lychee > /dev/null 2>&1")
      puts "\n❌ Error: lychee is not installed."
      puts "\nInstall lychee using one of these methods:"
      puts "  - cargo install lychee (requires Rust)"
      puts "  - brew install lychee (macOS)"
      puts "  - See https://lychee.cli.rs/ for more options"
      exit 1
    end

    # Run lychee with --offline to check only internal links
    success = system(
      "lychee",
      "--config", "lychee.toml",
      "--offline",
      "--format", "detailed",
      "docs/**/*.adoc",
      "README.adoc"
    )

    if success
      puts "\n✅ All internal documentation links are valid!"
    else
      puts "\n❌ Broken internal links found. See output above for details."
      exit 1
    end
  end

  desc "Check all links including external URLs (may have false positives)"
  task :links_all do
    puts "Checking all documentation links (internal + external)..."
    puts "⚠️  Note: External URLs may fail due to rate limiting or anti-bot measures"
    puts

    unless system("which lychee > /dev/null 2>&1")
      puts "\n❌ Error: lychee is not installed."
      puts "\nInstall lychee using one of these methods:"
      puts "  - cargo install lychee (requires Rust)"
      puts "  - brew install lychee (macOS)"
      puts "  - See https://lychee.cli.rs/ for more options"
      exit 1
    end

    success = system(
      "lychee",
      "--config", "lychee.toml",
      "--format", "detailed",
      "docs/**/*.adoc",
      "README.adoc"
    )

    if success
      puts "\n✅ All links are valid!"
    else
      puts "\n❌ Some links failed validation."
      puts "Note: External URL failures may be due to anti-bot measures, not actual broken links."
      exit 1
    end
  end

  desc "Check documentation links (verbose output)"
  task :links_verbose do
    puts "Checking internal documentation links (verbose)..."

    unless system("which lychee > /dev/null 2>&1")
      puts "\n❌ Error: lychee is not installed."
      puts "\nInstall lychee using one of these methods:"
      puts "  - cargo install lychee (requires Rust)"
      puts "  - brew install lychee (macOS)"
      puts "  - See https://lychee.cli.rs/ for more options"
      exit 1
    end

    success = system(
      "lychee",
      "--config", "lychee.toml",
      "--offline",
      "--format", "detailed",
      "--verbose",
      "docs/**/*.adoc",
      "README.adoc"
    )

    if success
      puts "\n✅ All internal links are valid!"
    else
      puts "\n❌ Broken links found. See output above for details."
      exit 1
    end
  end
end
