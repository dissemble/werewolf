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
      assert_match(/already dead/, err.message)
    end

    def test_killing_lumberjack_once_does_not_kill
      player = Player.new(:name => 'seth',  :role => 'lumberjack')
      player.kill!
      assert player.alive?
    end

    def test_killing_lumberjack_twice_does_kill
      player = Player.new(:name => 'seth',  :role => 'lumberjack')
      assert !player.kill!
      assert player.kill!
      assert !player.alive?
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
      assert_match(/only seer may see/, err.message)
    end

    def test_view_shows_team
      seer = Player.new(:name => 'seth', :role => 'seer')
      villager = Player.new(:name => 'john', :role => 'villager')
      villager.stubs(:team).returns('chaotic good')
      assert_equal 'chaotic good', seer.view(villager)
    end

    def test_team_is_evil_for_cultist
      player = Player.new(:name => 'seth', :role => 'cultist')
      assert_equal 'evil', player.team
    end
    
    def test_team_is_good_for_golem
      player = Player.new(:name => 'seth', :role => 'golem')
      assert_equal 'good', player.team
    end

    def test_team_is_good_for_lycan
      player = Player.new(:name => 'seth', :role => 'lycan')
      assert_equal 'good', player.team
    end

    def test_team_is_initially_good_for_sasquatch
      player = Player.new(:name => 'seth', :role => 'sasquatch')
      assert_equal 'good', player.team
    end

    def test_team_is_good_for_seer
      player = Player.new(:name => 'seth', :role => 'seer')
      assert_equal 'good', player.team
    end

    def test_team_is_good_for_tanner
      player = Player.new(:name => 'seth', :role => 'tanner')
      assert_equal 'good', player.team
    end

    def test_team_is_good_for_villager
      player = Player.new(:name => 'seth', :role => 'villager')
      assert_equal 'good', player.team
    end

    def test_team_is_evil_for_wolf
      player = Player.new(:name => 'seth', :role => 'wolf')
      assert_equal 'evil', player.team
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

    def test_cultist_appears_evil_to_seer
      assert_equal 'evil', Player.new(:name => 'seth', :role => 'cultist').apparent_team
    end

    def test_original_role_is_same_as_role
      # TODO:  move possible roles into Role class 
      all_roles = %w(beholder bodyguard cultist golem lycan seer tanner villager wolf)
      all_roles.each do |role|
        player = Player.new(:name => 'seth', :role => role)
        assert_equal player.role, player.original_role
      end
    end

    def test_original_role_when_role_assigned_twice
      player = Player.new(:name => 'seth')
      player.role = 'sasquatch'
      player.role = 'wolf'

      assert_equal 'wolf', player.role
      assert_equal 'sasquatch', player.original_role
    end

    def test_original_role_when_role_assigned_after_init
      player = Player.new(:name => 'seth', :role => 'sasquatch')
      player.role = 'wolf'

      assert_equal 'wolf', player.role
      assert_equal 'sasquatch', player.original_role
    end



    def test_to_s
      player = Player.new(:name => 'seth', :alive => false, :role => 'villager', :bot => false)
      assert_equal "#<Player name=seth>", player.to_s
    end



  end

end
