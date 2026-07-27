# frozen_string_literal: true

module Postsvg
  # Append-only SVG emitter. The Renderer / Visitors call methods on a
  # builder instance; #to_s finalizes and returns the SVG string.
  #
  # Determinism invariants:
  # - Two runs of the same input produce byte-equal output.
  # - IDs (clip1, grad1, pattern1) start at 1 on every SvgBuilder.new.
  # - Floats formatted through FormatNumber.
  # - <defs> block orders clipPaths, gradients, then patterns by
  #   registration order so output is reproducible.
  class SvgBuilder
    CLIP_PREFIX = "clip".freeze
    GRADIENT_PREFIX = "grad".freeze
    PATTERN_PREFIX = "pattern".freeze

    def initialize
      @buffer = String.new(capacity: 4096)
      @defs_buffer = String.new(capacity: 1024)
      @body_buffer = String.new(capacity: 4096)
      @clip_paths = {}     # path_d -> id
      @gradients = {}      # signature -> id
      @patterns = {}       # signature -> id
      @next_clip_id = 1
      @next_gradient_id = 1
      @next_pattern_id = 1
      @svg_open = false
      @group_depth = 0
      @header_height = nil
    end

    def open_svg(viewbox:, width:, height:)
      raise RenderError, "svg already open" if @svg_open

      @svg_open = true
      @header_height = height
      @buffer << %(<?xml version="1.0" encoding="UTF-8"?>\n)
      @buffer << %(<svg xmlns="http://www.w3.org/2000/svg" )
      @buffer << %(viewBox="#{viewbox}" )
      @buffer << %(width="#{num(width)}" height="#{num(height)}">\n)
      self
    end

    def open_y_flip_group
      open_group(transform: "translate(0 #{num(@header_height)}) scale(1 -1)")
    end

    def open_group(transform: nil, clip_path_id: nil)
      attrs = +""
      attrs << %( transform="#{transform}") if transform
      attrs << %( clip-path="url(##{clip_path_id})") if clip_path_id
      @body_buffer << %(<g#{attrs}>\n)
      @group_depth += 1
      self
    end

    def close_group
      raise RenderError, "no open group" if @group_depth.zero?

      @body_buffer << %(</g>\n)
      @group_depth -= 1
      self
    end

    # Register a clip path. Returns the id used. If +path_d+ was
    # previously registered, returns the existing id (dedup).
    def register_clip_path(path_d)
      return @clip_paths[path_d] if @clip_paths.key?(path_d)

      id = "#{CLIP_PREFIX}#{@next_clip_id}"
      @next_clip_id += 1
      @clip_paths[path_d] = id
      @defs_buffer << %(<clipPath id="#{id}"><path d="#{path_d}" /></clipPath>\n)
      id
    end

    def register_linear_gradient(stops:, x1:, y1:, x2:, y2:)
      sig = gradient_signature("linear", stops, [x1, y1, x2, y2])
      return @gradients[sig] if @gradients.key?(sig)

      id = "#{GRADIENT_PREFIX}#{@next_gradient_id}"
      @next_gradient_id += 1
      @gradients[sig] = id
      @defs_buffer << %(<linearGradient id="#{id}" )
      @defs_buffer << %(x1="#{num(x1)}" y1="#{num(y1)}" )
      @defs_buffer << %(x2="#{num(x2)}" y2="#{num(y2)}">\n)
      stops.each do |stop|
        @defs_buffer << %(<stop offset="#{num(stop[:offset])}" )
        @defs_buffer << %(stop-color="#{stop[:color].to_svg}" />\n)
      end
      @defs_buffer << %(</linearGradient>\n)
      id
    end

    def register_radial_gradient(stops:, cx:, cy:, r:, fx: nil, fy: nil)
      fx ||= cx
      fy ||= cy
      sig = gradient_signature("radial", stops, [cx, cy, r, fx, fy])
      return @gradients[sig] if @gradients.key?(sig)

      id = "#{GRADIENT_PREFIX}#{@next_gradient_id}"
      @next_gradient_id += 1
      @gradients[sig] = id
      @defs_buffer << %(<radialGradient id="#{id}" )
      @defs_buffer << %(cx="#{num(cx)}" cy="#{num(cy)}" r="#{num(r)}" )
      @defs_buffer << %(fx="#{num(fx)}" fy="#{num(fy)}">\n)
      stops.each do |stop|
        @defs_buffer << %(<stop offset="#{num(stop[:offset])}" )
        @defs_buffer << %(stop-color="#{stop[:color].to_svg}" />\n)
      end
      @defs_buffer << %(</radialGradient>\n)
      id
    end

    def register_pattern(width:, height:, body_blocks:)
      sig = "pattern:#{width}:#{height}:#{body_blocks.join('|')}"
      return @patterns[sig] if @patterns.key?(sig)

      id = "#{PATTERN_PREFIX}#{@next_pattern_id}"
      @next_pattern_id += 1
      @patterns[sig] = id
      @defs_buffer << %(<pattern id="#{id}" )
      @defs_buffer << %(width="#{num(width)}" height="#{num(height)}" )
      @defs_buffer << %(patternUnits="userSpaceOnUse">\n)
      body_blocks.each { |b| @defs_buffer << b }
      @defs_buffer << %(</pattern>\n)
      id
    end

    # Emit a <path>. +mode+ is one of :fill, :stroke, :fill_and_stroke.
    def path(d:, mode:, color: nil, stroke_color: nil,
             stroke_width: nil, line_cap: nil, line_join: nil,
             dash: nil, clip_path_id: nil, fill_id: nil)
      attrs = +"d=\"#{d}\""

      attrs << case mode
               when :fill
                 fill_attr(color, fill_id)
               when :stroke
                 %( fill="none" stroke="#{color_attr(stroke_color || color)}")
               when :fill_and_stroke
                 "#{fill_attr(color, fill_id)} stroke=\"#{color_attr(stroke_color || color)}\""
               else
                 %( fill="none" stroke="none")
               end

      attrs << %( stroke-width="#{num(stroke_width)}") if stroke_width && stroke_width != 1.0
      attrs << %( stroke-linecap="#{line_cap}") if line_cap && line_cap != :butt
      attrs << %( stroke-linejoin="#{line_join}") if line_join && line_join != :miter
      attrs << %( stroke-dasharray="#{dash}") if dash
      attrs << %( clip-path="url(##{clip_path_id})") if clip_path_id

      @body_buffer << %(<path #{attrs} />\n)
      self
    end

    def text(content:, x:, y:, font_family:, font_size:, color:,
             transform: nil)
      attrs = +""
      attrs << %( transform="#{transform}") if transform
      attrs << %( x="#{num(x)}" y="#{num(y)}")
      attrs << %( font-family="#{escape(font_family)}")
      attrs << %( font-size="#{num(font_size)}")
      attrs << %( fill="#{color_attr(color)}")
      @body_buffer << %(<text#{attrs}>#{escape(content)}</text>\n)
      self
    end

    def image(href:, x:, y:, width:, height:, transform: nil)
      attrs = +""
      attrs << %( transform="#{transform}") if transform
      attrs << %( x="#{num(x)}" y="#{num(y)}")
      attrs << %( width="#{num(width)}" height="#{num(height)}")
      attrs << %( href="#{escape(href)}")
      @body_buffer << %(<image#{attrs} />\n)
      self
    end

    def comment(text)
      @body_buffer << %(<!-- #{escape(text)} -->\n)
      self
    end

    def close_svg
      raise RenderError, "svg not open" unless @svg_open
      raise RenderError, "unclosed groups: #{@group_depth}" if @group_depth.positive?

      @buffer << "<defs>\n" unless @clip_paths.empty? && @gradients.empty? && @patterns.empty?
      @buffer << @defs_buffer
      @buffer << "</defs>\n" unless @clip_paths.empty? && @gradients.empty? && @patterns.empty?
      @buffer << @body_buffer
      @buffer << "</svg>\n"
      @svg_open = false
      self
    end

    def to_s
      raise RenderError, "svg not closed" if @svg_open

      @buffer.dup
    end

    # Expose internal buffers for testing only.
    def buffer_size
      @buffer.bytesize + @defs_buffer.bytesize + @body_buffer.bytesize
    end

    def registered_clip_count
      @clip_paths.size
    end

    def registered_gradient_count
      @gradients.size
    end

    private

    def num(value)
      FormatNumber.call(value)
    end

    def color_attr(color)
      return "none" if color.nil?

      color.is_a?(Color) ? color.to_svg : color.to_s
    end

    def fill_attr(color, fill_id)
      return %( fill="url(##{fill_id})") if fill_id

      %( fill="#{color_attr(color)}")
    end

    def gradient_signature(kind, stops, coords)
      stops_str = stops.map { |s| "#{s[:offset]}:#{s[:color]}" }.join(",")
      "#{kind}|#{stops_str}|#{coords.map { |c| num(c) }.join(',')}"
    end

    def escape(text)
      text.to_s
          .gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub('"', "&quot;")
          .gsub("'", "&#39;")
    end
  end
end
