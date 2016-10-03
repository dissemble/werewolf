require 'test_helper'

module Werewolf
  class SlackbotTest < Minitest::Test

    def test_can_observe_game
      game = Game.new
      slackbot = Werewolf::SlackBot.new
      game.add_observer(slackbot)
    end


    def test_tell_all_exists
      slackbot = Werewolf::SlackBot.new
      slackbot.stubs(:client).returns(mock(:say))
      slackbot.tell_all("foo")
    end


    def test_tell_player_exists
      slackbot = Werewolf::SlackBot.new
      slackbot.tell_player()
    end


    # TODO:  collapse next 2 tests
    def test_game_notifies_on_advance_time
      game = Game.new
      slackbot = Werewolf::SlackBot.new
      game.add_observer(slackbot)

      slackbot.expects(:update).with(
        :action => 'advance_time', 
        :message => "[Dawn], day 1")

      game.advance_time
    end


    def test_handle_advance_time_called_when_notified
      slackbot = Werewolf::SlackBot.new
      message = "bobby shaftoe's gone to sea"
      slackbot.expects(:handle_advance_time).once.with(:message => "#{message}")

      slackbot.update(
        :action => 'advance_time', 
        :message => message)
    end


    def test_advance_time_broadcasts_to_room
      slackbot = Werewolf::SlackBot.new
      message = "i see the moon, and the moon sees me."
      slackbot.expects(:tell_all).once.with(message)
      slackbot.handle_advance_time(:message => message)
    end


    # TODO:  collapse next 2 tests
    def test_game_notifies_on_join
      game = Game.new
      slackbot = Werewolf::SlackBot.new
      game.add_observer(slackbot)
      player = Player.new(:name => 'seth')

      slackbot.expects(:update).with(
        :action => 'join', 
        :message => "has joined the game", 
        :player => player)

      game.join(player)
    end


    def test_handle_join_called_when_notified
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth')
      message = "bobby shaftoe's gone to sea"
      slackbot.expects(:handle_join).once.with(:player => player, :message => "#{message}")

      slackbot.update(
        :action => 'join', 
        :message => message, 
        :player => player)
    end


    def test_handle_join_broadcast_to_room
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth')
      message = "ride a cock-horse to banbury cross"

      slackbot.expects(:tell_all).once.with("<@#{player.name}> #{message}")

      slackbot.handle_join(
        :message => message, 
        :player => player)
    end



    def test_game_notifies_on_join_error
      game = Game.new
      slackbot = Werewolf::SlackBot.new
      game.add_observer(slackbot)

      game.stubs(:active?).returns(true)
      slackbot.expects(:handle_join_error).once.with(
        :message =>'New players may not join once the game is active')

      game.join(Player.new(:name => 'seth'))
    end


    def test_handler_join_error_broadcasts_to_room
      slackbot = Werewolf::SlackBot.new
      message = "humpty dumpty sat on a wall"
      slackbot.expects(:tell_all).once.with(message)
      slackbot.handle_join_error(:message => message)
    end


    def test_tell_all
      slackbot = Werewolf::SlackBot.new
      message = 'ab cum de ex in pro sine sub'

      # TODO: mocking interface we don't own
      mock_client = mock("mock_client")
      mock_client.expects(:say).once.with(text: message, channel: 'G2FQMNAF8')
      slackbot.stubs(:client).returns(mock_client)

      slackbot.tell_all(message)
    end

  end
end