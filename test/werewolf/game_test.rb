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

    def test_new_game_time_period_is_night
      assert_equal 'night', Game.new.time_period
    end

    def test_join_adds_players_to_set
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'wesley')

      game.join(player1)
      game.join(player2)

      expected = Set.new [player1, player2]
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


    def test_add()
      game = Game.new
      game.add_username_to_game('seth')
      assert_equal 'seth', game.players.first.name
    end


    def test_slack_formatting_players
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'tom')
      player3 = Player.new(:name => 'bill')

      game.join(player1)
      game.join(player2)
      game.join(player3)

      expected = "Players:  <@seth>, <@tom>, <@bill>"
      assert_equal expected, game.format_players
    end

    def test_slack_formatting_players_when_no_players
      game = Game.new
      expected = "Zero players.  Type 'wolfbot join' to join the game."
      assert_equal expected, game.format_players
    end

    def test_slack_format_status_new_game
      game = Game.new
      assert_match(/No game running/, game.format_status)
      assert_match game.format_players, game.format_status
    end

    def test_slack_format_status_newly_active_game
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.start
      assert_match(/Game is active/, game.format_status)
      assert_match game.format_players, game.format_status
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

      game.players.each do |player|
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

    def test_communicate
      game = Game.new

      message = "a message"
      channel = "a channel"
      client = mock('client') # TODO:  mocking an interface i don't own
      client.expects(:say).once.with(text: message, channel: channel)

      game.communicate(message, client, channel)
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
      fake_format_time = "the the far end of town where the grickle-grass grows"
      fake_players = [1,2,3]
      game.stubs(:format_time).returns(fake_format_time)
      game.stubs(:players).returns(fake_players)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'status',
        :message => fake_format_time,
        :players => fake_players)
      game.add_observer(mock_observer)

      game.status
    end


    def test_process_vote_exists
      game = Game.new
      game.stubs(:communicate)
      game.process_vote('fakevoter', 'fakevotee', 'fakeclient', 'fakechannel')
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

  end

end
