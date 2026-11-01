require 'minitest/autorun'
require_relative '../src/fog/names'

class TestNames < Minitest::Test

  N = Fog::Names

  def test_examples_of_the_requirements
    refute_nil N.error('cab1', [ 'cab1-body' ])
    refute_nil N.error('cab1-front', [ 'cab1', 'cab1-body' ])
    assert_nil N.error('cab1', [ 'cab10-body' ])
    assert_nil N.error('cab10', [ 'cab1-body' ])
    assert_nil N.error('body', [ 'body 18 white' ])
  end

  def test_same_name_and_case
    refute_nil N.error('Cab1', [ 'cab1' ])
    refute_nil N.error('cab1', [ 'CAB1-BODY' ])
  end

  def test_empty_name
    assert_match(/no name/, N.error('', []))
  end

  def test_hardware_prefixes
    refute_nil N.error('f_cab', [])
    refute_nil N.error('G_cab', [])
    assert_nil N.error('fg_cab', [])
  end

end
