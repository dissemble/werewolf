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
      username = 'seth'
      game.join(Player.new(username))

      err = assert_raises(AlreadyJoinedError) {
        game.join(Player.new(username))
      }
      assert_match /already joined/, err.message
      assert_equal username, err.username
    end

    def test_join_raises_if_game_is_active
      game = Game.new
      game.stubs(:active?).returns(true)
      assert_raises(ActiveGameError) {
        game.join(Player.new('seth'))
      }
    end

    def test_game_can_be_started
      game = Game.new
      game.join(Player.new('seth'))
      game.start
    end

    def test_game_cannot_be_started_twice
      game = Game.new
      game.join(Player.new('seth'))
      game.start

      err = assert_raises(RuntimeError) {
        game.start
      }
      assert_match /Game is already active/, err.message
    end

    def test_game_needs_at_least_one_player_to_start
      game = Game.new
      err = assert_raises(RuntimeError) {
        game.start
      }
      assert_match /Game can't start until there is at least 1 player/, err.message
    end

    def test_once_started_game_is_active
      game = Game.new
      game.join(Player.new('seth'))
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
      game.join(Player.new('seth'))
      game.start
      assert_match /Game is active/, game.format_status
      assert_match game.format_players, game.format_status
    end

    def test_roles_are_assigned_at_game_start
      game = Game.new
      game.join(Player.new('seth'))
      game.expects(:assign_roles)

      game.start
    end

    def test_all_players_have_roles_once_game_starts
      game = Game.new
      game.join(Player.new('seth'))
      game.join(Player.new('tom'))
      game.join(Player.new('bill'))
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

    def test_process_join_exists
      game = Game.new
      game.stubs(:communicate)
      game.process_join("fakeusername", "fakeclient", "fakechannel")
    end

    def test_process_join_joins_new_player_to_game
      game = Game.new

      username = "fakeusername"
      mock_player = mock('player')
      
      Player.expects(:new).once.with(username).returns(mock_player)
      game.expects(:join).once.with(mock_player)
      game.stubs(:communicate)

      game.process_join(username, "fakeclient", "fakechannel")
    end
  
    def test_process_join_communicates_to_users
      game = Game.new

      client = mock("fakeclient")
      channel = "fakechannel"
      username = "fakeusername"
      status = 'foo'

      game.stubs(:format_status).returns(status)
      game.expects(:communicate).with(regexp_matches(/#{username}/), client, channel)
      game.expects(:communicate).with(status, client, channel)
      
      game.process_join(username, client, channel)
    end

    def test_process_join_communicates_already_joined_error
      game = Game.new

      username = 'seth'
      game.stubs(:join).raises(AlreadyJoinedError.new(username, 'omg problems'))
      game.expects(:communicate).with(regexp_matches(/#{username}.*omg problems/), anything, anything)

      game.process_join('fakeusername', 'fakeclient', 'fakechannel')
    end

    def test_process_join_communicates_active_game_error
      game = Game.new

      username = 'seth'
      game.stubs(:join).raises(ActiveGameError.new(username, 'omg problems'))
      game.expects(:communicate).with(regexp_matches(/#{username}.*you can't join a game after it starts/), anything, anything)

      game.process_join('fakeusername', 'fakeclient', 'fakechannel')
    end

    def test_process_start_starts_game
      game = Game.new
      game.expects(:start).once
      game.stubs(:communicate)
      game.process_start('fakeusername', 'fakeclient', 'fakechannel')
    end


    def test_process_start_communicates_status
      game = Game.new

      username = 'seth'
      status = 'fake_status'
      game.stubs(:format_status).returns(status)
      game.stubs(:start)
      game.expects(:communicate).once
        .with(regexp_matches(/#{username}.*has started the game/), anything, anything)
      game.expects(:communicate).once
        .with(regexp_matches(/#{username}.*#{status}/), anything, anything)
      game.expects(:communicate).once
        .with('[Dawn]', anything, anything)

      game.process_start(username, 'fakeclient', 'fakechannel')
    end


    def test_process_start_communicates_errors
      game = Game.new

      username = 'fakeusername'
      err = RuntimeError.new('oops')
      game.stubs(:start).raises(err)
      game.expects(:communicate).with(regexp_matches(/#{username}.*#{err.message}/), anything, anything)

      game.process_start(username, 'fakeclient', 'fakechannel')
    end


    def test_process_vote_exists
      game = Game.new
      game.stubs(:communicate)
      game.process_vote('fakevoter', 'fakevotee', 'fakeclient', 'fakechannel')
    end





  end

end
