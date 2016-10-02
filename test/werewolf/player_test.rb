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

    def test_hash_uses_hash_of_player_name
      player = Player.new('seth')
      assert_equal player.name.hash, player.hash
    end

    def test_eql_uses_eql_of_player_name
      player1 = Player.new('seth')
      player2 = Player.new('seth')
      assert player1.eql?(player2)
    end

    def test_can_set_and_get_role
      player = Player.new('seth')
      player.role = 'wolf'
      assert_equal 'wolf', player.role
    end

  end

end
