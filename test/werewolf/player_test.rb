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
      err = assert_raises(RuntimeError) {
        player.kill!
      }
      assert_match /already dead/, err.message
    end

    def test_seer_can_view
      player = Player.new(:name => 'seth', :role => 'seer')
      player.view(player)
    end

    def test_non_seer_cannot_view
      player = Player.new(:name => 'seth', :role => 'wolf')
      err = assert_raises(RuntimeError) {
        player.view(player)
      }
      assert_match /only seer may see/, err.message
    end

    def test_view_shows_team
      seer = Player.new(:name => 'seth', :role => 'seer')
      villager = Player.new(:name => 'john', :role => 'villager')
      villager.stubs(:team).returns('chaotic good')
      assert_equal 'chaotic good', seer.view(villager)
    end

    def test_team_is_good_for_seer
      seer = Player.new(:name => 'seth', :role => 'seer')
      assert_equal 'good', seer.team
    end

    def test_team_is_good_for_villager
      villager = Player.new(:name => 'seth', :role => 'villager')
      assert_equal 'good', villager.team
    end

    def test_team_is_evil_for_wolf
      villager = Player.new(:name => 'seth', :role => 'wolf')
      assert_equal 'evil', villager.team
    end

    def test_team_is_evil_for_cultist
      villager = Player.new(:name => 'seth', :role => 'cultist')
      assert_equal 'evil', villager.team
    end

    def test_team_is_good_for_lycan
      villager = Player.new(:name => 'seth', :role => 'lycan')
      assert_equal 'good', villager.team
    end

    def test_normal_players_are_not_bots
      player = Player.new(:name => 'seth')
      assert !player.bot?
    end

    def test_can_create_a_bot
      player = Player.new(:name => 'seth', :bot => true)
      assert player.bot?
    end

    def test_initialize_can_override_alive
      player = Player.new(:name => 'seth', :alive => false)
      assert player.dead?
    end

    def test_apparent_team
      assert_equal 'evil', Player.new(:name => 'seth', :role => 'wolf').apparent_team
      assert_equal 'good', Player.new(:name => 'tom', :role => 'villager').apparent_team
    end

    def test_lycan_appears_evil_to_seer
      seer = Player.new(:name => 'seth', :role => 'seer')
      lycan = Player.new(:name => 'tom', :role => 'lycan')
      assert_equal 'evil', seer.view(lycan)
    end

    def test_apparent_team_is_evil_for_lycan
      assert_equal 'evil', Player.new(:name => 'seth', :role => 'lycan').apparent_team
    end

    def test_to_s
      player = Player.new(:name => 'seth', :alive => false, :role => 'villager', :bot => false)
      assert_equal "#<Player name=seth>", player.to_s
    end



  end

end
