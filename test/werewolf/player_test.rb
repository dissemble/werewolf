require 'test_helper'

module Werewolf

  class PlayerTest < Minitest::Test
  	def test_cant_initialize_without_name
  		assert_raises(ArgumentError) {
  			Player.new
  		}
  	end
    
    def test_can_set_and_get_role
      player = Player.new(name => 'seth')
      player.role = 'wolf'
      assert_equal 'wolf', player.role
    end

    def test_init_with_name_and_role
      player = Player.new(:name => 'seth', :role => 'wolf')
      assert_equal 'seth', player.name
      assert_equal 'wolf', player.role
    end

    def test_new_players_are_alive
      player = Player.new(:name => 'seth')
      assert player.alive?
      assert !player.dead?
    end

    def test_players_are_no_longer_alive_when_killed
      player = Player.new(:name => 'seth')
      assert player.alive?
      player.kill!
      assert !player.alive?
    end

    def test_killing_twice_raises_error
      player = Player.new(:name => 'seth')
      player.kill!
      assert_raises(RuntimeError) {
        player.kill!
      }
    end


  end

end
