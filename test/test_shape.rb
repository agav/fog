require 'minitest/autorun'
require_relative '../src/fog/vec'
require_relative '../src/fog/shape'

class TestShape < Minitest::Test

  S = Fog::Shape

  def rect(*points)
    points.map { |p| p.map(&:to_f) }
  end

  # A tube along Y: width w, depth d, height h, wall t
  def tube(w: 600, d: 300, h: 800, t: 18)
    inner_w = w - t
    inner_h = h - t
    ring = lambda do |y|
      { outer: rect([ 0, y, 0 ], [ w, y, 0 ], [ w, y, h ], [ 0, y, h ]),
        inners: [ rect([ t, y, t ], [ inner_w, y, t ], [ inner_w, y, inner_h ], [ t, y, inner_h ]) ] }
    end
    x_wall = ->(x, z0, z1) { { outer: rect([ x, 0, z0 ], [ x, d, z0 ], [ x, d, z1 ], [ x, 0, z1 ]) } }
    z_wall = ->(z, x0, x1) { { outer: rect([ x0, 0, z ], [ x1, 0, z ], [ x1, d, z ], [ x0, d, z ]) } }
    [ ring.call(0), ring.call(d),
      x_wall.call(0, 0, h), x_wall.call(w, 0, h), z_wall.call(0, 0, w), z_wall.call(h, 0, w),
      x_wall.call(t, t, inner_h), x_wall.call(inner_w, t, inner_h),
      z_wall.call(t, t, inner_w), z_wall.call(inner_h, t, inner_w) ]
  end

  def transform(faces, &block)
    faces.map do |f|
      { outer: f[:outer].map(&block), inners: (f[:inners] || []).map { |l| l.map(&block) } }
    end
  end

  def test_valid_tube
    result = S.analyze(tube)
    assert_nil result.error
    assert_in_delta 1.0, result.axis[1].abs, 1e-9
  end

  def test_turned_around_z
    a = Math::PI / 7
    faces = transform(tube) { |x, y, z| [ x * Math.cos(a) - y * Math.sin(a), x * Math.sin(a) + y * Math.cos(a), z ] }
    assert_nil S.analyze(faces).error
  end

  def test_scaled_group_is_measured_in_model_space
    faces = transform(tube(t: 9)) { |x, y, z| [ x * 2, y, z * 2 ] }
    assert_nil S.analyze(faces).error
  end

  def test_reversed_faces
    faces = tube.map { |f| { outer: f[:outer].reverse, inners: f[:inners] } }
    assert_nil S.analyze(faces).error
  end

  def test_coplanar_edges_split_a_face
    faces = tube
    wall = faces.delete_at(2)   # the left outer wall, 300 x 800
    faces << { outer: rect([ 0, 0, 0 ], [ 0, 100, 0 ], [ 0, 100, 800 ], [ 0, 0, 800 ]) }
    faces << { outer: rect([ 0, 100, 0 ], [ 0, 300, 0 ], [ 0, 300, 800 ], [ 0, 100, 800 ]) }
    refute_nil wall
    assert_nil S.analyze(faces).error
  end

  def test_wall_thickness
    assert_match(/18 mm thick/, S.analyze(tube(t: 16)).error)
    assert_nil S.analyze(tube(t: 18.05)).error
    assert_match(/18 mm thick/, S.analyze(tube(t: 18.2)).error)
  end

  def test_solid_box_is_not_valid
    faces = tube.first(2).map { |f| { outer: f[:outer] } } + tube[2, 4]
    refute_nil S.analyze(faces).error
  end

  def test_blind_pocket_is_not_valid
    faces = tube
    faces[1] = { outer: faces[1][:outer] }   # closed back
    faces << { outer: rect([ 18, 280, 18 ], [ 582, 280, 18 ], [ 582, 280, 782 ], [ 18, 280, 782 ]) }
    refute_nil S.analyze(faces).error
  end

  def test_face_in_the_opening_is_not_valid
    faces = tube
    faces[0] = { outer: faces[0][:outer] }   # front face has no hole
    assert_match(/closed walls/, S.analyze(faces).error)
  end

  def test_opening_must_be_horizontal
    faces = transform(tube) { |x, y, z| [ x, z, y ] }   # axis along Z
    assert_match(/horizontal/, S.analyze(faces).error)
  end

  def test_tilted_is_not_valid
    a = 0.2
    faces = transform(tube) { |x, y, z| [ x, y * Math.cos(a) - z * Math.sin(a), y * Math.sin(a) + z * Math.cos(a) ] }
    assert_match(/vertical or horizontal/, S.analyze(faces).error)
  end

  def test_edges_outside_the_box
    assert_match(/outside/, S.analyze(tube, [ [ -50.0, 0.0, 0.0 ] ]).error)
    assert_nil S.analyze(tube, [ [ 300.0, 100.0, 0.0 ] ]).error
  end

  def test_empty
    refute_nil S.analyze([]).error
  end

end
