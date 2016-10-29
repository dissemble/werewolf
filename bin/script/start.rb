#paste into 'bundle exec bin/console' session
# or:
#    load 'bin/script/start.rb'

SlackRubyBot::Client.logger.level = Logger::INFO
game = Werewolf::Game.instance

slackbot = Werewolf::SlackBot.new(token: ENV['SLACK_API_TOKEN'], aliases: ['fangbot'])
game.add_observer(slackbot)

slackbot.start_async

sleep 2
