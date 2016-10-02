#!/usr/bin/env ruby

require "bundler/setup"
require "werewolf"

if ENV['SLACK_API_TOKEN'].nil?
  puts "ERROR:  Please set the'SLACK_API_TOKEN' environment variable and try again"
  exit(1)
end

SlackRubyBot::Client.logger.level = Logger::INFO
Werewolf::Game.new
Werewolf::App.instance.run