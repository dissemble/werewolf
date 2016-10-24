#!/usr/bin/env ruby

require "bundler/setup"
require "werewolf"

if ENV['SLACK_API_TOKEN'].nil?
  puts "ERROR:  Please set the'SLACK_API_TOKEN' environment variable and try again"
  exit(1)
end

SlackRubyBot::Client.logger.level = Logger::INFO
game = Werewolf::Game.instance

slackbot = Werewolf::SlackBot.new(token: ENV['SLACK_API_TOKEN'], aliases: ['fangbot'])
game.add_observer(slackbot)

slackbot.start_async

time_increment = 1
warning_tick = 10

loop do
  sleep time_increment

  if game.active?
    if game.round_expired?
      game.advance_time 
    else
      game.tick time_increment
    end

    if (game.time_remaining_in_round == warning_tick)
      game.notify_all("#{game.time_period} ending in #{game.time_remaining_in_round} seconds")
    end

    puts "time remaining in round: #{game.time_remaining_in_round}"
  end

  
end
