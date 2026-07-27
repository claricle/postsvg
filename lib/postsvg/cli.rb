# frozen_string_literal: true

require "thor"

module Postsvg
  # Command-line interface. Thor-based. Auto-detects conversion
  # direction by file extension in +batch+.
  class CLI < Thor
    package_name "postsvg"

    desc "convert INPUT [OUTPUT]",
         "Convert PostScript/EPS file to SVG (legacy alias for to-svg)"
    long_desc <<~DESC
      Convert a PostScript (.ps) or Encapsulated PostScript (.eps) file to SVG.

      If OUTPUT is not specified, SVG is written to stdout.

      Examples:

        $ postsvg convert input.ps output.svg
        $ postsvg convert input.eps > output.svg
    DESC
    def convert(input_path, output_path = nil)
      handle_input(input_path, output_path, method(:read_ps_to_svg),
                   direction: "PS/EPS -> SVG")
    end

    desc "to-svg INPUT [OUTPUT]", "Convert PostScript/EPS to SVG"
    long_desc <<~DESC
      Alias for `convert`. Reads PS or EPS, writes SVG.
    DESC
    def to_svg(input_path, output_path = nil)
      convert(input_path, output_path)
    end

    desc "to-ps INPUT [OUTPUT]", "Convert SVG to PostScript"
    long_desc <<~DESC
      Convert an SVG file to PostScript source. If OUTPUT is not specified,
      PS source is written to stdout.

      Examples:

        $ postsvg to-ps input.svg output.ps
        $ postsvg to-ps input.svg > output.ps
    DESC
    def to_ps(input_path, output_path = nil)
      handle_input(input_path, output_path, method(:read_svg_to_ps),
                   direction: "SVG -> PS")
    end

    desc "to-eps INPUT [OUTPUT]", "Convert SVG to Encapsulated PostScript"
    long_desc <<~DESC
      Like to-ps but emits an EPSF-3.0 header and a single-page program
      suitable for embedding.
    DESC
    def to_eps(input_path, output_path = nil)
      handle_input(input_path, output_path, method(:read_svg_to_eps),
                   direction: "SVG -> EPS")
    end

    desc "batch INPUT_DIR [OUTPUT_DIR]",
         "Convert all PS/EPS/SVG files in a directory"
    long_desc <<~DESC
      Auto-detects direction by file extension:

        .ps, .eps   -> .svg
        .svg        -> .ps

      Output goes to OUTPUT_DIR if given, otherwise to INPUT_DIR.
    DESC
    def batch(input_dir, output_dir = nil)
      unless Dir.exist?(input_dir)
        say "Error: Input directory '#{input_dir}' not found", :red
        exit 1
      end

      Dir.mkdir(output_dir) if output_dir && !Dir.exist?(output_dir)

      files = Dir.glob(File.join(input_dir, "*.{ps,eps,svg}"), File::FNM_CASEFOLD)
      if files.empty?
        say "No PS, EPS, or SVG files found in #{input_dir}", :yellow
        return
      end

      say "Found #{files.size} file(s) to convert", :cyan
      files.each do |path|
        convert_in_batch(path, input_dir, output_dir)
      end
    end

    desc "version", "Show version"
    def version
      say "postsvg version #{Postsvg::VERSION}"
    end

    private

    def handle_input(input_path, output_path, reader, direction:)
      unless File.exist?(input_path)
        say "Error: Input file '#{input_path}' not found", :red
        exit 1
      end

      output = reader.call(File.read(input_path))
      if output_path
        File.write(output_path, output)
        say "Converted #{input_path} -> #{output_path} (#{direction})", :green
      else
        puts output
      end
    rescue Postsvg::Error => e
      say "Conversion error: #{e.message}", :red
      exit 2
    rescue StandardError => e
      say "Unexpected error: #{e.message}", :red
      say e.backtrace.join("\n"), :red if options[:verbose]
      exit 2
    end

    def read_ps_to_svg(content)
      Postsvg.to_svg(content)
    end

    def read_svg_to_ps(content)
      Postsvg.to_ps(content)
    end

    def read_svg_to_eps(content)
      Postsvg.to_eps(content)
    end

    def convert_in_batch(path, input_dir, output_dir)
      ext = File.extname(path).downcase
      basename = File.basename(path, ".*")
      out_ext =
        case ext
        when ".svg" then ".ps"
        else ".svg"
        end
      out_dir = output_dir || input_dir
      out_path = File.join(out_dir, "#{basename}#{out_ext}")

      content = File.read(path)
      output =
        case ext
        when ".svg" then Postsvg.to_ps(content)
        else Postsvg.to_svg(content)
        end
      File.write(out_path, output)
      say "  #{path} -> #{out_path}", :green
    rescue Postsvg::Error => e
      say "  #{path}: #{e.message}", :red
    end
  end
end
