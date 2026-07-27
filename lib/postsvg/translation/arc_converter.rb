# frozen_string_literal: true

module Postsvg
  module Translation
    # SVG endpoint-to-center arc parametrization converter. Implements
    # the algorithm documented in the SVG 1.1 implementation notes
    # (appendix F.6.5). Returns the PS-style center parametrization:
    # center x/y, normalized radii, rotation, and start/end angles.
    module ArcConverter
      EPSILON = 1e-12

      module_function

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/ParameterLists
      def endpoint_to_center(x1:, y1:, rx:, ry:, x_axis_rotation:,
                             large_arc:, sweep:, x2:, y2:)
        rx = rx.abs
        ry = ry.abs
        # If the endpoints coincide, the arc is degenerate.
        return [x1, y1, 0.0, 0.0, 0.0, 0.0, 0.0] if rx < EPSILON || ry < EPSILON

        phi = x_axis_rotation * Math::PI / 180.0
        cos_phi = Math.cos(phi)
        sin_phi = Math.sin(phi)

        # Step 1: rotate and scale (x1,y1) into the unit-circle frame.
        dx = (x1 - x2) / 2.0
        dy = (y1 - y2) / 2.0
        x1p =  cos_phi * dx + sin_phi * dy
        y1p = -sin_phi * dx + cos_phi * dy

        # Ensure radii are large enough; if not, scale them up.
        rx_sq = rx * rx
        ry_sq = ry * ry
        x1p_sq = x1p * x1p
        y1p_sq = y1p * y1p
        lambda = (x1p_sq / rx_sq) + (y1p_sq / ry_sq)
        if lambda > 1.0
          sqrt_lambda = Math.sqrt(lambda)
          rx *= sqrt_lambda
          ry *= sqrt_lambda
          rx_sq = rx * rx
          ry_sq = ry * ry
        end

        # Step 2: compute center (cx', cy') in the rotated frame.
        sign = (large_arc == sweep) ? -1 : 1
        num = rx_sq * ry_sq - rx_sq * y1p_sq - ry_sq * x1p_sq
        den = rx_sq * y1p_sq + ry_sq * x1p_sq
        den = EPSILON if den.abs < EPSILON
        coef = sign * Math.sqrt([num / den, 0.0].max)
        cxp =  coef * (rx * y1p) / ry
        cyp = -coef * (ry * x1p) / rx

        # Step 3: rotate (cx', cy') back into original frame.
        cx = cos_phi * cxp - sin_phi * cyp + (x1 + x2) / 2.0
        cy = sin_phi * cxp + cos_phi * cyp + (y1 + y2) / 2.0

        # Step 4: compute angles.
        ux = (x1p - cxp) / rx
        uy = (y1p - cyp) / ry
        vx = (-x1p - cxp) / rx
        vy = (-y1p - cyp) / ry

        theta1 = angle_between(1.0, 0.0, ux, uy)
        delta_theta = angle_between(ux, uy, vx, vy) % (2 * Math::PI)
        delta_theta -= 2 * Math::PI if !sweep && delta_theta.positive?

        theta2 = theta1 + delta_theta

        [cx, cy, rx, ry, phi, theta1 * 180.0 / Math::PI, theta2 * 180.0 / Math::PI]
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/ParameterLists

      def angle_between(ux, uy, vx, vy)
        dot = ux * vx + uy * vy
        len = Math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
        return 0.0 if len < EPSILON

        cos_val = (dot / len).clamp(-1.0, 1.0)
        sign = (ux * vy - uy * vx).negative? ? -1.0 : 1.0
        sign * Math.acos(cos_val)
      end
    end
  end
end
