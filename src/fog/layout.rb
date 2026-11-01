module Fog

  # Unit frame and panels of the body (requirements, sections 3.4 to 3.7). All values are in
  # millimeters, in model space. No SketchUp here.
  module Layout

    # origin: left, front, bottom corner of the outer box
    Frame = Struct.new(:origin, :right, :back, :top, :width, :depth, :height) do
      # Model point of the unit frame coordinates
      def point(x, y, z)
        Vec.add(origin, Vec.add(Vec.scale(right, x), Vec.add(Vec.scale(back, y), Vec.scale(top, z))))
      end
    end

    # role: :left, :right, :top, :bottom; red, green, blue: axes; size: [ along red, along green, along blue ]
    Panel = Struct.new(:role, :origin, :red, :green, :blue, :size) do
      def corner(r, g, b)
        Vec.add(origin, Vec.add(Vec.scale(red, r), Vec.add(Vec.scale(green, g), Vec.scale(blue, b))))
      end

      # The 12 box edges as a flat list of point pairs
      def lines
        Layout.box_lines(self)
      end
    end

    # The front side is the end of the opening that is more to the camera. to_camera: direction
    # from the center of the shape to the camera. If the two sides are equal, the front is on +axis.
    def self.frame(points, axis, to_camera)
      axis = Vec.unit([ axis[0], axis[1], 0.0 ])
      back = Vec.dot(axis, to_camera) >= 0 ? Vec.scale(axis, -1.0) : axis
      top = [ 0.0, 0.0, 1.0 ]
      right = Vec.cross(back, top)
      low, high = [ right, back, top ].map { |d| points.map { |p| Vec.dot(p, d) }.minmax }.transpose
      origin = Vec.add(Vec.scale(right, low[0]), Vec.add(Vec.scale(back, low[1]), Vec.scale(top, low[2])))
      Frame.new(origin, right, back, top, high[0] - low[0], high[1] - low[1], high[2] - low[2])
    end

    # option :a: top and bottom cover the sides; option :b: the sides cover top and bottom
    def self.panels(frame, option, thickness)
      w = frame.width
      d = frame.depth
      h = frame.height
      t = thickness
      cover = option == :a
      side = cover ? h - 2 * t : h
      cap = cover ? w : w - 2 * t
      side_low = cover ? t : 0.0
      cap_x = cover ? 0.0 : t
      up = [ 0.0, 0.0, 1.0 ]
      down = [ 0.0, 0.0, -1.0 ]
      to_right = [ 1.0, 0.0, 0.0 ]
      back = [ 0.0, 1.0, 0.0 ]
      [
        _panel(frame, :left, [ 0.0, 0.0, side_low + side ], down, back, [ side, d, t ]),
        _panel(frame, :right, [ w, 0.0, side_low ], up, back, [ side, d, t ]),
        _panel(frame, :top, [ cap_x, 0.0, h - t ], to_right, back, [ cap, d, t ]),
        _panel(frame, :bottom, [ cap_x, 0.0, 0.0 ], to_right, back, [ cap, d, t ])
      ]
    end

    def self._panel(frame, role, origin, red, green, size)
      zero = frame.point(0.0, 0.0, 0.0)
      axis = ->(v) { Vec.sub(frame.point(*v), zero) }
      red = axis.call(red)
      green = axis.call(green)
      Panel.new(role, frame.point(*origin), red, green, Vec.cross(red, green), size)
    end

    def self.box_lines(panel)
      l, w, t = panel.size
      c = [ [ 0, 0, 0 ], [ l, 0, 0 ], [ l, w, 0 ], [ 0, w, 0 ], [ 0, 0, t ], [ l, 0, t ], [ l, w, t ], [ 0, w, t ] ]
          .map { |p| panel.corner(*p) }
      [ [ 0, 1 ], [ 1, 2 ], [ 2, 3 ], [ 3, 0 ], [ 4, 5 ], [ 5, 6 ], [ 6, 7 ], [ 7, 4 ],
        [ 0, 4 ], [ 1, 5 ], [ 2, 6 ], [ 3, 7 ] ].flat_map { |a, b| [ c[a], c[b] ] }
    end

    # The outer rectangle of the front side as point pairs
    def self.front_lines(frame)
      w = frame.width
      h = frame.height
      c = [ frame.point(0.0, 0.0, 0.0), frame.point(w, 0.0, 0.0), frame.point(w, 0.0, h), frame.point(0.0, 0.0, h) ]
      (0...4).flat_map { |i| [ c[i], c[(i + 1) % 4] ] }
    end

  end

end
