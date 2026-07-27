# frozen_string_literal: true

module Postsvg
  # Immutable graphics state snapshot. Mutations return new instances
  # via +with(...)+. The GraphicsStack pushes/pops these.
  #
  # Fields mirror PLRM §7.2 graphics state operators. Optional fields
  # are +nil+ meaning "not set in this state"; the renderer falls back
  # to defaults at emit time.
  class GraphicsContext
    attr_reader :ctm, :fill_color, :stroke_color, :stroke_width,
                :line_cap, :line_join, :miter_limit, :dash,
                :font_name, :font_size, :clip_paths, :last_text_position,
                :fill_rule

    DEFAULTS = {
      ctm: Matrix.new,
      fill_color: Color::BLACK,
      stroke_color: Color::BLACK,
      stroke_width: 1.0,
      line_cap: :butt,
      line_join: :miter,
      miter_limit: 10.0,
      dash: nil,
      font_name: "Helvetica",
      font_size: 12.0,
      clip_paths: [],
      last_text_position: nil,
      fill_rule: :nonzero,
    }.freeze

    def initialize(**fields)
      merged = DEFAULTS.merge(fields)
      @ctm = merged[:ctm]
      @fill_color = merged[:fill_color]
      @stroke_color = merged[:stroke_color]
      @stroke_width = merged[:stroke_width]
      @line_cap = merged[:line_cap]
      @line_join = merged[:line_join]
      @miter_limit = merged[:miter_limit]
      @dash = merged[:dash]
      @font_name = merged[:font_name]
      @font_size = merged[:font_size]
      @clip_paths = merged[:clip_paths].freeze
      @last_text_position = merged[:last_text_position]
      @fill_rule = merged[:fill_rule]
      freeze
    end

    def with(**overrides)
      GraphicsContext.new(
        ctm: overrides.fetch(:ctm, @ctm),
        fill_color: overrides.fetch(:fill_color, @fill_color),
        stroke_color: overrides.fetch(:stroke_color, @stroke_color),
        stroke_width: overrides.fetch(:stroke_width, @stroke_width),
        line_cap: overrides.fetch(:line_cap, @line_cap),
        line_join: overrides.fetch(:line_join, @line_join),
        miter_limit: overrides.fetch(:miter_limit, @miter_limit),
        dash: overrides.fetch(:dash, @dash),
        font_name: overrides.fetch(:font_name, @font_name),
        font_size: overrides.fetch(:font_size, @font_size),
        clip_paths: overrides.fetch(:clip_paths, @clip_paths),
        last_text_position: overrides.fetch(:last_text_position, @last_text_position),
        fill_rule: overrides.fetch(:fill_rule, @fill_rule),
      )
    end

    def push_clip_path(path_d)
      with(clip_paths: @clip_paths + [path_d])
    end

    def identity_ctm?
      @ctm.identity?
    end

    def clipped?
      !@clip_paths.empty?
    end
  end
end
