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

    def test_join_adds_players_to_set
      game = Game.new
      player1 = Player.new('seth')
      player2 = Player.new('wesley')

      game.join(player1)
      game.join(player2)

      expected = Set.new [player1, player2]
      assert_equal expected, game.players
    end

    def test_raise_if_same_player_name_added_twice
      game = Game.new
      game.join(Player.new('seth'))
      game.join(Player.new('wesley'))
    end

    def test_game_can_be_started
      Game.new.start
    end

    def test_once_started_game_is_active
      game = Game.new
      game.start
      assert game.active?
    end

    def test_slack_formatting_players
      game = Game.new
      player1 = Player.new('seth')
      player2 = Player.new('wesley')
      player3 = Player.new('plough')

      game.join(player1)
      game.join(player2)
      game.join(player3)

      expected = "Players:  <@seth>, <@wesley>, <@plough>"
      assert_equal expected, game.format_players
    end

    def test_slack_formatting_players_when_no_players
      game = Game.new
      expected = "Zero players.  Type 'wolfbot join' to join the game."
      assert_equal expected, game.format_players
    end

    def test_slack_format_status_new_game
      game = Game.new
      assert_match /No game running/, game.format_status
      assert_match game.format_players, game.format_status
    end

    def test_slack_format_status_newly_active_game
      game = Game.new
      game.start
      assert_match /Game is active/, game.format_status
      assert_match game.format_players, game.format_status
    end

    def test_assign_players_to_roles
      # TODO
    end

    def test_starting_assigns_roles
      # TODO
    end

    def test_instance_method_returns_new_instance
      assert_equal Game, Game.instance.class
    end

    def test_instance_method_returns_same_instance_when_called_twice
      x = Game.instance
      y = Game.instance
      assert_equal x, y
    end




  end

end
