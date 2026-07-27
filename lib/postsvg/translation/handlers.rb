# frozen_string_literal: true

module Postsvg
  module Translation
    # SVG element handler catalogue. One handler class per supported
    # SVG element. Each implements +.call(element, context)+.
    module Handlers
      autoload :SvgHandler, "postsvg/translation/handlers/svg_handler"
      autoload :GroupHandler, "postsvg/translation/handlers/group_handler"
      autoload :PathHandler, "postsvg/translation/handlers/path_handler"
      autoload :RectHandler, "postsvg/translation/handlers/rect_handler"
      autoload :CircleHandler, "postsvg/translation/handlers/circle_handler"
      autoload :EllipseHandler, "postsvg/translation/handlers/ellipse_handler"
      autoload :LineHandler, "postsvg/translation/handlers/line_handler"
      autoload :PolylineHandler, "postsvg/translation/handlers/polyline_handler"
      autoload :PolygonHandler, "postsvg/translation/handlers/polygon_handler"
      autoload :TextHandler, "postsvg/translation/handlers/text_handler"
      autoload :ImageHandler, "postsvg/translation/handlers/image_handler"
      autoload :DefsHandler, "postsvg/translation/handlers/defs_handler"
      autoload :ClipPathHandler, "postsvg/translation/handlers/clip_path_handler"
      autoload :OpenHandler, "postsvg/translation/handlers/open_handler"
      autoload :Shared, "postsvg/translation/handlers/shared"
    end
  end
end
