require 'minitest/autorun'
require_relative '../src/fog/vec'
require_relative '../src/fog/layout'

class TestLayout < Minitest::Test

  L = Fog::Layout
  V = Fog::Vec
  T = 18.0

  # Box 600 x 300 x 800 with the opening along Y
  POINTS = [ [ 0.0, 0.0, 0.0 ], [ 600.0, 300.0, 800.0 ] ].freeze

  def frame(to_camera = [ 0.0, -1000.0, 0.0 ])
    L.frame(POINTS, [ 0.0, 1.0, 0.0 ], to_camera)
  end

  def panels(option, f = frame)
    L.panels(f, option, T).to_h { |p| [ p.role, p ] }
  end

  # Model box of a panel: [ [ min x, max x ], [ min y, max y ], [ min z, max z ] ]
  def box(panel)
    panel.lines.transpose.map { |c| [ c.min.round(6), c.max.round(6) ] }
  end

  def test_frame_from_the_front
    f = frame
    assert_equal [ 1.0, 0.0, 0.0 ], f.right.map(&:to_f).map { |v| v + 0.0 }
    assert_equal [ 0.0, 1.0, 0.0 ], f.back
    assert_equal [ 0.0, 0.0, 0.0 ], f.origin.map { |v| v + 0.0 }
    assert_equal [ 600.0, 300.0, 800.0 ], [ f.width, f.depth, f.height ]
  end

  def test_frame_from_the_other_side
    f = frame([ 0.0, 1000.0, 0.0 ])
    assert_equal [ -1.0, 0.0, 0.0 ], f.right.map { |v| v + 0.0 }
    assert_equal [ 0.0, -1.0, 0.0 ], f.back.map { |v| v + 0.0 }
    assert_equal [ 600.0, 300.0, 0.0 ], f.origin
    # left as seen from this side is at x = 600
    assert_equal [ 582.0, 600.0 ], box(panels(:a, f)[:left])[0]
  end

  def test_frame_with_equal_sides_selects_one
    assert_equal [ 0.0, -1.0, 0.0 ], frame([ 1000.0, 0.0, 0.0 ]).back.map { |v| v + 0.0 }
  end

  def test_turned_unit_keeps_the_size
    a = Math::PI / 5
    turn = ->(x, y, z) { [ x * Math.cos(a) - y * Math.sin(a), x * Math.sin(a) + y * Math.cos(a), z ] }
    corners = [ 0.0, 600.0 ].product([ 0.0, 300.0 ], [ 0.0, 800.0 ]).map { |p| turn.call(*p) }
    f = L.frame(corners, turn.call(0.0, 1.0, 0.0), turn.call(0.0, -1.0, 0.0))
    assert_in_delta 600.0, f.width, 1e-6
    assert_in_delta 300.0, f.depth, 1e-6
    assert_in_delta 800.0, f.height, 1e-6
  end

  def test_axes_of_the_requirements
    p = panels(:a)
    assert_equal [ [ 0.0, 0.0, -1.0 ], [ 0.0, 1.0, 0.0 ], [ 1.0, 0.0, 0.0 ] ], axes(p[:left])
    assert_equal [ [ 0.0, 0.0, 1.0 ], [ 0.0, 1.0, 0.0 ], [ -1.0, 0.0, 0.0 ] ], axes(p[:right])
    assert_equal [ [ 1.0, 0.0, 0.0 ], [ 0.0, 1.0, 0.0 ], [ 0.0, 0.0, 1.0 ] ], axes(p[:top])
    assert_equal [ [ 1.0, 0.0, 0.0 ], [ 0.0, 1.0, 0.0 ], [ 0.0, 0.0, 1.0 ] ], axes(p[:bottom])
  end

  def axes(panel)
    [ panel.red, panel.green, panel.blue ].map { |a| a.map { |v| v.round(9) + 0.0 } }
  end

  def test_origins_option_a
    p = panels(:a)
    assert_equal [ 0.0, 0.0, 782.0 ], p[:left].origin
    assert_equal [ 0.0, 0.0, 782.0 ], p[:top].origin
    assert_equal [ 600.0, 0.0, 18.0 ], p[:right].origin
    assert_equal [ 0.0, 0.0, 0.0 ], p[:bottom].origin
  end

  def test_origins_option_b
    p = panels(:b)
    assert_equal [ 0.0, 0.0, 800.0 ], p[:left].origin
    assert_equal [ 18.0, 0.0, 782.0 ], p[:top].origin
    assert_equal [ 600.0, 0.0, 0.0 ], p[:right].origin
    assert_equal [ 18.0, 0.0, 0.0 ], p[:bottom].origin
  end

  def test_boxes_option_a
    p = panels(:a)
    assert_equal [ [ 0.0, 18.0 ], [ 0.0, 300.0 ], [ 18.0, 782.0 ] ], box(p[:left])
    assert_equal [ [ 582.0, 600.0 ], [ 0.0, 300.0 ], [ 18.0, 782.0 ] ], box(p[:right])
    assert_equal [ [ 0.0, 600.0 ], [ 0.0, 300.0 ], [ 782.0, 800.0 ] ], box(p[:top])
    assert_equal [ [ 0.0, 600.0 ], [ 0.0, 300.0 ], [ 0.0, 18.0 ] ], box(p[:bottom])
  end

  def test_boxes_option_b
    p = panels(:b)
    assert_equal [ [ 0.0, 18.0 ], [ 0.0, 300.0 ], [ 0.0, 800.0 ] ], box(p[:left])
    assert_equal [ [ 582.0, 600.0 ], [ 0.0, 300.0 ], [ 0.0, 800.0 ] ], box(p[:right])
    assert_equal [ [ 18.0, 582.0 ], [ 0.0, 300.0 ], [ 782.0, 800.0 ] ], box(p[:top])
    assert_equal [ [ 18.0, 582.0 ], [ 0.0, 300.0 ], [ 0.0, 18.0 ] ], box(p[:bottom])
  end

  def test_material_is_on_the_positive_side_of_blue
    %i[a b].each do |option|
      panels(option).each_value do |panel|
        assert_equal T, panel.size[2]
        expected = panel.corner(0, 0, T)
        assert_equal 18.0, V.length(V.sub(expected, panel.origin)).round(6)
      end
    end
  end

  def test_axes_are_right_handed
    %i[a b].each do |option|
      panels(option).each_value do |panel|
        assert_equal panel.blue.map { |v| v.round(9) }, V.cross(panel.red, panel.green).map { |v| v.round(9) }
      end
    end
  end

  def test_front_lines_are_on_the_front
    lines = L.front_lines(frame)
    assert_equal 8, lines.length
    assert(lines.all? { |p| p[1].abs < 1e-9 })
  end

end
