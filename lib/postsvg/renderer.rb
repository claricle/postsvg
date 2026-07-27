# frozen_string_literal: true

module Postsvg
  # Top-level orchestrator for PS -> SVG. Owns lifecycle: BoundingBox
  # pre-scan, builder open/close, visitor dispatch.
  class Renderer
    MAX_OUTPUT_BYTES = 100 * 1024 * 1024

    def self.call(program, options = Options.new)
      new(program, options).call
    end

    attr_reader :program, :options, :builder, :visitor

    def initialize(program, options)
      raise ArgumentError, "program must be a Model::Program" unless program.is_a?(Model::Program)

      @program = program
      @options = options
      @builder = SvgBuilder.new
      @visitor = Visitors::PsVisitor.new(builder: @builder)
    end

    def call
      open_svg
      wrap_y_flip do
        visitor.visit_program(program)
      rescue Postsvg::QuitSignal
        # PS +quit+ ends program execution; suppress and finalize SVG.
      end
      builder.close_svg
      result = builder.to_s
      enforce_size_limit(result)
      result
    end

    private

    def open_svg
      viewbox, width, height = compute_viewbox
      builder.open_svg(viewbox: viewbox, width: width, height: height)
    end

    def wrap_y_flip
      builder.open_y_flip_group
      yield
      builder.close_group
    end

    # Determine viewBox from (1) explicit override, (2) header
    # BoundingBox / HiResBoundingBox, (3) default A4 page size.
    def compute_viewbox
      return options_viewbox if options_viewbox

      bbox = program.header.hires_bounding_box || program.header.bounding_box
      if bbox
        llx, lly, urx, ury = bbox
        width = urx - llx
        height = ury - lly
        viewbox = "#{FormatNumber.call(llx)} #{FormatNumber.call(lly)} " \
                  "#{FormatNumber.call(width)} #{FormatNumber.call(height)}"
        [viewbox, width, height]
      else
        width, height = options.page_size
        ["0 0 #{FormatNumber.call(width)} #{FormatNumber.call(height)}", width, height]
      end
    end

    def options_viewbox
      return nil unless options.viewbox_override

      vb = options.viewbox_override
      return vb if vb.is_a?(Array) && vb.length == 4

      [vb, nil, nil]
    end

    def enforce_size_limit(result)
      return unless result.bytesize > MAX_OUTPUT_BYTES

      raise SizeLimitError,
            "SVG output #{result.bytesize} bytes exceeds limit #{MAX_OUTPUT_BYTES}"
    end
  end
end
