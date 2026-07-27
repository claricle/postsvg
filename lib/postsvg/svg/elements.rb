# frozen_string_literal: true

module Postsvg
  module Svg
    # Element subclass catalogue. Each subclass is registered with its
    # SVG tag name. The +load_all!+ class method forces each autoload
    # to fire; this populates the Element.registry so Svg::Parser can
    # dispatch by tag name.
    module Elements
      autoload :Svg, "postsvg/svg/elements/svg"
      autoload :Group, "postsvg/svg/elements/group"
      autoload :Path, "postsvg/svg/elements/path"
      autoload :Rect, "postsvg/svg/elements/rect"
      autoload :Circle, "postsvg/svg/elements/circle"
      autoload :Ellipse, "postsvg/svg/elements/ellipse"
      autoload :Line, "postsvg/svg/elements/line"
      autoload :Polyline, "postsvg/svg/elements/polyline"
      autoload :Polygon, "postsvg/svg/elements/polygon"
      autoload :Text, "postsvg/svg/elements/text"
      autoload :Image, "postsvg/svg/elements/image"
      autoload :Defs, "postsvg/svg/elements/defs"
      autoload :ClipPath, "postsvg/svg/elements/clip_path"

      class << self
        def load_all!
          constants.each { |c| const_get(c) }
        end
      end
    end
  end
end
