module Fog

  # Small vector math on [ x, y, z ] arrays, so that the geometry code runs without SketchUp
  module Vec

    def self.add(a, b)
      [ a[0] + b[0], a[1] + b[1], a[2] + b[2] ]
    end

    def self.sub(a, b)
      [ a[0] - b[0], a[1] - b[1], a[2] - b[2] ]
    end

    def self.scale(a, s)
      [ a[0] * s, a[1] * s, a[2] * s ]
    end

    def self.dot(a, b)
      a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
    end

    def self.cross(a, b)
      [ a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0] ]
    end

    def self.length(a)
      Math.sqrt(dot(a, a))
    end

    def self.unit(a)
      scale(a, 1.0 / length(a))
    end

  end

end
