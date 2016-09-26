require 'test_helper'

module Werewolf

  class PlayerTest < Minitest::Test
  	def test_cant_initialize_without_name
  		assert_raises(ArgumentError) {
  			Player.new
  		}
  	end

  	def test_initialize_sets_name
  		assert_equal 'seth', Player.new('seth').name
  	end

  	def test_new_player_has_nil_side
  		assert Player.new('seth').side.nil?
  	end

  end

end
