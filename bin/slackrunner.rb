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

loop do
  sleep 3
  game.advance_time if game.active?
end
