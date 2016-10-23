#paste into 'bundle exec bin/console' session

SlackRubyBot::Client.logger.level = Logger::INFO
game = Werewolf::Game.instance

slackbot = Werewolf::SlackBot.new(token: ENV['SLACK_API_TOKEN'], aliases: ['fangbot'])
game.add_observer(slackbot)

slackbot.start_async

sleep 2


tom = Werewolf::Player.new(:name => 'tom', :bot => true)
game.join(tom)