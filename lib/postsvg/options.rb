# frozen_string_literal: true

module Postsvg
  # Shared options for both directions. Frozen on construction.
  class Options
    attr_reader :eps, :width, :height, :viewbox_override, :verbose, :page_size

    DEFAULT_PAGE_SIZE = [595, 842].freeze # A4 in PostScript points

    def initialize(eps: false, width: nil, height: nil, viewbox_override: nil,
                   verbose: false, page_size: nil)
      @eps = eps
      @width = width
      @height = height
      @viewbox_override = viewbox_override
      @verbose = verbose
      @page_size = page_size || DEFAULT_PAGE_SIZE
      freeze
    end

    def to_h
      {
        eps: @eps, width: @width, height: @height,
        viewbox_override: @viewbox_override, verbose: @verbose,
        page_size: @page_size,
      }
    end
  end
end
