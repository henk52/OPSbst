require_relative 'CliOptionHandling'
require 'test/unit'
 
class TestGetNextCliArgument < Test::Unit::TestCase
 
  def test_simple
    assert_equal("UPS", CliOptionHandling.GetNextCliArgument() )
  end
 
end
