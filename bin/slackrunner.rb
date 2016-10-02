#!/usr/bin/env ruby

require "bundler/setup"
require "werewolf"

if ENV['SLACK_API_TOKEN'].nil?
  puts "ERROR:  Please set the'SLACK_API_TOKEN' environment variable and try again"
  exit(1)
end

SlackRubyBot::Client.logger.level = Logger::INFO
game = Werewolf::Game.new

slackbot = Werewolf::SlackBot.new(token: ENV['SLACK_API_TOKEN'], aliases: ['fangbot'])
slackbot.start_async

while true do
  sleep 2
  game.advance_time
end
