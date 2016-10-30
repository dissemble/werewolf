#!/usr/bin/env ruby

require "bundler/setup"
require "werewolf"

if ENV['SLACK_API_TOKEN'].nil?
  puts "ERROR:  Please set the 'SLACK_API_TOKEN' environment variable and try again"
  exit(1)
end

SlackRubyBot::Client.logger.level = Logger::INFO
game = Werewolf::Game.instance

slackbot = Werewolf::SlackBot.new(token: ENV['SLACK_API_TOKEN'], aliases: ['!', 'w'])

# slackbot.channel = 'C2EP92WF3' # werewolf
# slackbot.channel = 'G2FQMNAF8' # werewolf-bot-dev

unless ENV['SLACK_CHANNEL'].nil?
  slackbot.channel = ENV['SLACK_CHANNEL']
end

game.add_observer(slackbot)

slackbot.start_async

time_increment = 1
warning_tick = 30

loop do
  sleep time_increment

  if game.active?
    if game.round_expired?
      game.advance_time
    elsif game.voting_finished?
      game.notify_all "All votes have been cast; dusk will come early."
      game.advance_time
    elsif game.night_finished?
      game.notify_all "All night actions are complete; dawn will come early."
      game.advance_time
    else
      game.tick time_increment

      if (game.time_remaining_in_round == warning_tick)
        game.notify_all("#{game.time_period} ending in #{game.time_remaining_in_round} seconds")
      end
    end

    if game.winner?
      game.end_game
    end
    puts "time remaining in round: #{game.time_remaining_in_round}"
  end


end
