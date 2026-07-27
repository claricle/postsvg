# frozen_string_literal: true

module Postsvg
  module Model
    # Top-level program node. Carries DSC header (BoundingBox, Title,
    # etc.) and the body — an ordered list of statements, each either a
    # literal (Number/Name/String/Array/Procedure/Dictionary) or an
    # Operator instance.
    class Program
      attr_reader :header, :body

      def initialize(header: Header.new, body: [])
        @header = header
        @body = body
        freeze
      end

      def with(header: nil, body: nil)
        Program.new(header: header || @header, body: body || @body)
      end

      def append(statement)
        Program.new(header: @header, body: @body + [statement])
      end

      def concat(statements)
        Program.new(header: @header, body: @body + statements)
      end

      # DSC header: structured document structuring comments.
      class Header
        attr_reader :bounding_box, :hires_bounding_box, :title, :creator,
                    :creation_date, :pages, :page_count, :epsf,
                    :language_level, :custom

        def initialize(bounding_box: nil, hires_bounding_box: nil, title: nil,
                       creator: nil, creation_date: nil, pages: nil,
                       page_count: nil, epsf: false, language_level: nil,
                       custom: {})
          @bounding_box = bounding_box
          @hires_bounding_box = hires_bounding_box
          @title = title
          @creator = creator
          @creation_date = creation_date
          @pages = pages
          @page_count = page_count
          @epsf = epsf
          @language_level = language_level
          @custom = custom.dup.freeze
          freeze
        end

        def with(**overrides)
          Header.new(**to_h.merge(overrides))
        end

        def to_h
          {
            bounding_box: bounding_box, hires_bounding_box: hires_bounding_box,
            title: title, creator: creator, creation_date: creation_date,
            pages: pages, page_count: page_count, epsf: epsf,
            language_level: language_level, custom: custom,
          }
        end
      end
    end
  end
end
