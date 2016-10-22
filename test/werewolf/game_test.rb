require 'test_helper'

module Werewolf

  class GameTest < Minitest::Test

    # def test_aspirations
    #   game = Game.new
    #   seer = Player.new(:name => 'a_seer')
    #   wolf = Player.new(:name => 'a_wolf')
    #   villager1 = Player.new(:name => 'a_villager_1')
    #   villager2 = Player.new(:name => 'a_villager_2')
    #   villager3 = Player.new(:name => 'a_villager_3')

    #   game.join(seer)
    #   game.join(wolf)
    #   game.join(villager1)
    #   game.join(villager2)
    #   game.join(villager3)

    #   # setup roles...

    #   # start 5 player game
    #   game.start

    #   # Night 0
    #   assert_equal 'good', seer.see('villager1')
    #   game.advance_time

    #   # Day 1
    #   seer.vote('a_villager_2')
    #   wolf.vote('a_villager_2')
    #   villager1.vote('a_seer')
    #   villager2.vote('a_wolf')
    #   #villager3 doesn't vote

    #   # Night 1
    #   game.advance_time
    #   assert game.players('a_villager_2').dead?
    #   assert_equal 'evil' seer.see(a_wolf)
    #   wolf.nightkill('villager3')
    #   assert game.players('a_villager_3').dead?

    #   # Day 2
    #   game.advance_time
    #   seer.vote('wolf')
    #   wolf.vote('seer')
    #   villager1.vote('wolf')

    #   # Game over
    #   game.advance_time
    #   assert game.players('wolf').dead?
    #   assert_equal 'good' game.winner
    # end



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

    def test_new_game_time_period_is_night
      assert_equal 'night', Game.new.time_period
    end

    def test_join_add_to_players
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'wesley')

      game.join(player1)
      game.join(player2)

      expected = {player1.name => player1, player2.name =>player2}
      assert_equal expected, game.players
    end


    def test_same_name_cant_join_twice
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'seth')

      game.join(player1)
      game.join(player2)

      expected = {player1.name => player1}
      assert_equal expected, game.players
    end


    def test_game_can_be_started
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.start
    end


    def test_game_cannot_be_started_twice
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.start

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'tell_all', 
        :message => 'Game is already active')
      game.add_observer(mock_observer)
      game.expects(:assign_roles).never

      game.start
    end


    def test_game_needs_at_least_one_player_to_start
      game = Game.new

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'tell_all', 
        :message => "Game can't start until there is at least 1 player")
      game.add_observer(mock_observer)
      game.expects(:assign_roles).never

      game.start
    end


    def test_once_started_game_is_active
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.start
      assert game.active?
    end


    def test_add_username_to_game()
      game = Game.new
      game.add_username_to_game('seth')
      # TODO:  london school?
      assert_equal 'seth', game.players.keys.first
    end


    def test_roles_are_assigned_at_game_start
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.expects(:assign_roles)

      game.start
    end


    def test_all_players_have_roles_once_game_starts
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.join(Player.new(:name => 'tom'))
      game.join(Player.new(:name => 'bill'))
      game.start

      game.players.values.each do |player|
        assert player.role
      end
    end

    def test_instance_method_returns_new_instance
      assert_equal Game, Game.instance.class
    end

    def test_instance_method_returns_same_instance_when_called_twice
      x = Game.instance
      y = Game.instance
      assert_equal x, y
    end


    def test_format_time_when_game_active
      game = Game.new
      game.stubs(:active?).returns(true)
      game.stubs(:time_period).returns('night')
      game.stubs(:day_number).returns(17)
      assert_equal "It is night (day 17)", game.format_time
    end


    def test_format_time_when_game_inactive
      game = Game.new
      game.stubs(:active?).returns(false)
      assert_equal "No game running", game.format_time
    end


    def test_notification_when_status_called
      game = Game.new
      fake_format_time = "the far end of town where the grickle-grass grows"
      fake_players = {1 => 2, 3 => 4}
      game.stubs(:format_time).returns(fake_format_time)
      game.stubs(:players).returns(fake_players)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'status',
        :message => fake_format_time,
        :players => [2, 4])
      game.add_observer(mock_observer)

      game.status
    end


    def test_create_time_period_generator
      game = Game.new
      generator = game.create_time_period_generator
      assert_equal ['night', 0],  generator.next
      assert_equal ['day', 1],    generator.next
      assert_equal ['night', 1],  generator.next
      assert_equal ['day', 2],    generator.next
      assert_equal ['night', 2],  generator.next
      assert_equal ['day', 3],    generator.next
    end


    def test_advance_time
      game = Game.new
      assert_equal 'night', game.time_period
      assert_equal 0, game.day_number

      game.advance_time
      assert_equal 'day', game.time_period
      assert_equal 1, game.day_number

      game.advance_time
      assert_equal 'night', game.time_period
      assert_equal 1, game.day_number

      game.advance_time
      assert_equal 'day', game.time_period
      assert_equal 2, game.day_number
    end


    def test_game_notifies_when_time_changes
      game = Game.new

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'advance_time',
        :message => '[Dawn], day 1')
      game.add_observer(mock_observer)

      game.advance_time
    end


    def test_game_notifies_when_player_joins
      game = Game.new
      player = Player.new(:name => 'seth')

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(:action => 'join', :player => player, :message => 'has joined the game')
      game.add_observer(mock_observer)

      game.join player
    end


    def test_notification_when_already_joined
      game = Game.new
      player = Player.new(:name => 'seth')
      game.join(player)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'join_error', 
        :player => player,
        :message => "you already joined!")
      game.add_observer(mock_observer)

      game.join(player)
    end


    def test_notification_when_joining_active_game
      game = Game.new
      player = Player.new(:name => 'seth')
      game.expects(:active?).once.returns(true)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'join_error', 
        :player => player,
        :message => "game is active, joining is not allowed")
      game.add_observer(mock_observer)

      game.join(player)
    end



    def test_start_notifies_room_and_players
      game = Game.new
      start_initiator = "fakeuser"
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'tom')
      game.join(player1)
      game.join(player2)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'start', 
        :start_initiator => start_initiator, 
        :message => 'has started the game')
      mock_observer.expects(:update).once.with(
        :action => 'tell_player', 
        :player => player1, 
        :message => 'boom')
      mock_observer.expects(:update).once.with(
        :action => 'tell_player', 
        :player => player2, 
        :message => 'boom')
      game.stubs(:status)
      game.add_observer(mock_observer)

      game.start(start_initiator)
    end


    def test_start_calls_status
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.join(Player.new(:name => 'tom'))
      game.expects(:status)

      game.start
    end


    def test_vote
      game = Game.new
      game.add_username_to_game('seth')
      game.vote('seth', 'seth')
    end


    def test_can_only_vote_for_real_players
      game = Game.new
      game.add_username_to_game('seth')
      assert_raises(RuntimeError) {
        game.vote('seth', 'babar')
      }
    end


    def test_can_only_vote_for_living_players
      #TODO
    end


    def test_can_only_vote_during_day
      #TODO
    end


    def test_only_real_players_can_vote
      game = Game.new
      game.add_username_to_game('seth')
      assert_raises(RuntimeError) {
        game.vote('babar', 'seth')
      }
    end


    def test_tally_starts_empty
      game = Game.new
      assert_equal Hash.new, game.tally
    end




    def test_tally_after_voting
      game = Game.new
      game.add_username_to_game('seth')
      game.add_username_to_game('tom')
      game.add_username_to_game('bill')
      game.vote('seth', 'tom')
      game.vote('tom', 'bill')
      game.vote('bill', 'tom')

      expected = {'tom' => ['seth', 'bill'], 'bill' => ['tom']}
      assert_equal expected, game.tally
    end


    def test_kill_player_calls_kill_on_player
      game = Game.new
      player = Player.new(:name => 'seth')
      game.join player
      player.expects(:kill!).once
      game.kill_player player
    end


    def test_kill_player_makes_them_dead
      game = Game.new
      player = Player.new(:name => 'seth')
      game.join player
      game.kill_player player
      assert player.dead?
    end


    def test_kill_player_notifies
      game = Game.new
      player = Player.new(:name => 'seth')
      game.join player
      
      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'kill_player', 
        :player => player,
        :message => 'With pitchforks in hand, the townsfolk killed')
      game.add_observer(mock_observer)

      game.kill_player player
    end



    def test_lynch_called_at_dusk
      game = Game.new
      game.advance_time
      assert_equal 'day', game.time_period

      game.expects(:lynch).once

      game.advance_time
    end


    def test_lynch_with_no_votes
      game = Game.new
      game.lynch
    end


    def test_lynch_kills_tally_leader
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'john')
      game.join(player1)
      game.join(player2)

      game.vote('seth', 'seth')
      game.vote('john', 'seth')
      assert player1.alive?
      game.expects(:kill_player).once.with(player1)

      game.lynch
    end


    def test_lynch_kills_no_one_if_tally_is_tied
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'john')
      game.join(player1)
      game.join(player2)

      game.vote('seth', 'john')
      game.vote('john', 'seth')

      game.lynch
      assert player1.alive?
      assert player2.alive?
    end


    def test_tally_is_cleared_after_lynch
      game = Game.new
      game.add_username_to_game('seth')
      game.vote('seth', 'seth')
      assert_equal 1, game.tally.size

      game.lynch
      assert_equal 0, game.tally.size
    end


    def test_notification_on_successful_vote
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'tom')
      game.join(player1)
      game.join(player2)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'vote', 
        :voter => player1,
        :votee => player2,
        :message => 'voted for')
      game.add_observer(mock_observer)

      game.vote('seth', 'tom')
    end


    def test_notification_on_failed_vote
      #TODO
    end




  end

end
