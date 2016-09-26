require 'test_helper'

module Werewolf

  class GameTest < Minitest::Test

    def test_new_game_is_inactive
      assert !Game.new.active?
    end

    def test_new_game_has_no_players
      assert Game.new.players.empty?
    end

    def test_new_game_has_nil_active_roles
      assert Game.new.active_roles.nil?
    end

    def test_new_game_is_on_day_0
      assert_equal 0, Game.new.day_number
    end

    def test_new_game_time_period_is_nil
      assert Game.new.time_period.nil?
    end

    def test_player_can_join_game
      game = Game.new
      player = Player.new('seth')

      game.join(player)

      expected = Set.new [player]
      assert_equal expected, game.players
    end

    def test_game_can_be_started
      Game.new.start
    end

    def test_once_started_game_is_active
      game = Game.new
      game.start
      assert game.active?
    end

    def test_assign_players_to_roles
      # TODO
    end

    def test_starting_assigns_roles
      # TODO
    end




  end

end
