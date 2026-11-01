module Fog

  # Checks that a drawn group is a rectangular tube with 18 mm walls (requirements, section 3.1).
  # The input is plain data in millimeters, in model space:
  #   faces: [ { outer: [ point, ... ], inners: [ [ point, ... ], ... ] }, ... ]
  #   points: all points of the edges
  # Face normals are not used for the direction: a drawn face can be reversed.
  module Shape

    THICKNESS = 18.0
    TOLERANCE = 0.1      # mm
    ANGLE = 0.002        # sine of the largest angle between "parallel" directions
    UP = [ 0.0, 0.0, 1.0 ].freeze

    # error: the reason why the shape is not valid, or nil; axis: direction of the opening
    Result = Struct.new(:error, :axis, :points)

    def self.analyze(faces, points = [])
      return Result.new('It has no faces.') if faces.empty?
      faces = faces.map { |f| _face(f) }
      return Result.new('It has a face with no area.') if faces.any? { |f| f[:normal].nil? }
      directions = _directions(faces)
      error = _check_directions(directions)
      return Result.new(error) if error

      planes = directions.map { |d| _planes(faces, d) }
      axis_index = planes.index { |p| p.length == 2 }
      if planes.map(&:length).sort != [ 2, 4, 4 ]
        return Result.new('It must have one through opening and four walls.')
      end
      return Result.new('The opening must be horizontal.') if _parallel?(directions[axis_index], UP)

      across = [ 0, 1, 2 ] - [ axis_index ]
      error = _check_walls(across.map { |i| planes[i] }) ||
              _check_areas(planes[axis_index], planes[across[0]], planes[across[1]]) ||
              _check_points(points, directions, planes)
      return Result.new(error) if error

      all_points = faces.flat_map { |f| f[:points] } + points
      Result.new(nil, directions[axis_index], all_points)
    end

    def self._face(face)
      outer = _newell(face[:outer])
      area = Vec.length(outer) / 2.0 - (face[:inners] || []).sum { |loop_| Vec.length(_newell(loop_)) / 2.0 }
      points = face[:outer] + (face[:inners] || []).flatten(1)
      { point: face[:outer].first, points: points, area: area,
        normal: Vec.length(outer) > 1e-9 ? Vec.unit(outer) : nil }
    end

    def self._newell(points)
      sum = [ 0.0, 0.0, 0.0 ]
      points.each_with_index do |p, i|
        sum = Vec.add(sum, Vec.cross(p, points[(i + 1) % points.length]))
      end
      sum
    end

    def self._parallel?(a, b)
      Vec.length(Vec.cross(a, b)) < ANGLE
    end

    # The different normal lines of the faces (a line has no sign)
    def self._directions(faces)
      faces.each_with_object([]) do |face, directions|
        directions << face[:normal] unless directions.any? { |d| _parallel?(d, face[:normal]) }
      end
    end

    def self._check_directions(directions)
      return 'Its outer shape must be a rectangular box.' if directions.length != 3
      perpendicular = directions.combination(2).all? { |a, b| Vec.dot(a, b).abs < ANGLE }
      return 'Its outer shape must be a rectangular box.' unless perpendicular
      return 'Its walls must be vertical or horizontal.' unless directions.any? { |d| _parallel?(d, UP) }
      nil
    end

    # Sorted planes across one direction: [ { offset:, area: }, ... ]
    def self._planes(faces, direction)
      faces = faces.select { |f| _parallel?(f[:normal], direction) }
      faces.map { |f| [ Vec.dot(f[:point], direction), f[:area] ] }.sort_by(&:first)
           .each_with_object([]) do |(offset, area), planes|
        if planes.last && offset - planes.last[:offset] <= TOLERANCE
          planes.last[:area] += area
        else
          planes << { offset: offset, area: area }
        end
      end
    end

    def self._check_walls(across)
      across.each do |planes|
        offsets = planes.map { |p| p[:offset] }
        [ offsets[1] - offsets[0], offsets[3] - offsets[2] ].each do |wall|
          next if (wall - THICKNESS).abs <= TOLERANCE
          return "All walls must be #{THICKNESS.round} mm thick. One wall is #{wall.round(1)} mm."
        end
      end
      nil
    end

    # The sum of the face areas in each plane shows that the planes have the shape of a tube:
    # for example, a face that closes the opening makes the area too large.
    def self._check_areas(ends, across_a, across_b)
      a, inner_a = _sizes(across_a)
      b, inner_b = _sizes(across_b)
      depth = ends[1][:offset] - ends[0][:offset]
      ring = a * b - inner_a * inner_b
      slack = (a + b) * TOLERANCE * 4
      ok = ends.all? { |p| (p[:area] - ring).abs <= slack } &&
           _walls_ok?(across_a, b, inner_b, depth) && _walls_ok?(across_b, a, inner_a, depth)
      ok ? nil : 'It must be four closed walls around one rectangular opening.'
    end

    def self._sizes(planes)
      [ planes[3][:offset] - planes[0][:offset], planes[2][:offset] - planes[1][:offset] ]
    end

    def self._walls_ok?(planes, width, inner_width, depth)
      slack = (width + depth) * TOLERANCE * 4
      [ [ 0, width ], [ 1, inner_width ], [ 2, inner_width ], [ 3, width ] ].all? do |i, w|
        (planes[i][:area] - w * depth).abs <= slack
      end
    end

    def self._check_points(points, directions, planes)
      inside = points.all? do |point|
        directions.each_with_index.all? do |d, i|
          offset = Vec.dot(point, d)
          offset >= planes[i].first[:offset] - TOLERANCE && offset <= planes[i].last[:offset] + TOLERANCE
        end
      end
      inside ? nil : 'It has edges outside the box.'
    end

  end

end
