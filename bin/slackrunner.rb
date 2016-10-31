#!/usr/bin/env ruby

require "bundler/setup"
require "werewolf"

if ENV['SLACK_API_TOKEN'].nil?
  puts "ERROR:  Please set the 'SLACK_API_TOKEN' environment variable and try again"
  exit(1)
end

channel = ENV['SLACK_CHANNEL']
if channel.nil?
  channel = 'G2FQMNAF8' # werewolf-bot-dev
  # channel = 'C2EP92WF3' # werewolf
end

SlackRubyBot::Client.logger.level = Logger::INFO
game = Werewolf::Game.instance

slackbot = Werewolf::SlackBot.new(token: ENV['SLACK_API_TOKEN'], aliases: ['!', 'w'])
slackbot.channel = channel
game.add_observer(slackbot)
slackbot.start_async

event_loop = Werewolf::EventLoop.new(game)

loop do
  sleep event_loop.time_increment
  event_loop.next
end
