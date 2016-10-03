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
      slackbot.tell_all()
    end


    def test_tell_player_exists
      slackbot = Werewolf::SlackBot.new
      slackbot.tell_player()
    end


    def test_advance_time_calls_tell_all
      slackbot = Werewolf::SlackBot.new
      slackbot.expects(:tell_all).once
      slackbot.advance_time
    end


    def test_send_message_when_time_advances
      game = Game.new
      slackbot = Werewolf::SlackBot.new
      game.add_observer(slackbot)

      slackbot.expects(:advance_time)

      game.advance_time

    end

  end
end