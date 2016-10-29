#paste into 'bundle exec bin/console' session

SlackRubyBot::Client.logger.level = Logger::INFO
game = Werewolf::Game.instance

slackbot = Werewolf::SlackBot.new(token: ENV['SLACK_API_TOKEN'], aliases: ['fangbot'])
game.add_observer(slackbot)

slackbot.start_async

sleep 2


seer = Werewolf::Player.new(:name => 'bill', :bot => true)
wolf = Werewolf::Player.new(:name => 'tom', :bot => true)
beholder = Werewolf::Player.new(:name => 'seth', :bot => true)
villager2 = Werewolf::Player.new(:name => 'john', :bot => true)
villager3 = Werewolf::Player.new(:name => 'monty', :bot => true)


game.join(seer)
game.join(wolf)
game.join(beholder)
game.join(villager2)
game.join(villager3)

# start 5 player game
game.start('seer')

# reassign roles
seer.role = 'seer'
wolf.role = 'wolf'
beholder.role = 'beholder'
villager2.role = 'villager'
villager3.role = 'cultist'

# Night 0
seer.view(beholder)
game.advance_time

# Day 1
game.vote(voter_name='bill', 'john')
game.vote(voter_name='tom', 'john')
game.vote(voter_name='seth', 'bill')
game.vote(voter_name='john', 'tom')
#villager3 doesn't vote
game.vote_tally
game.status

# Night 1
game.advance_time
game.players['john'].dead?
seer.view(wolf)
game.nightkill('tom', 'monty')
game.players['monty'].dead?
game.status

# Day 2
game.advance_time
game.players['monty'].dead?

game.vote(voter_name='bill', 'tom')
game.vote(voter_name='tom', 'bill')
game.vote(voter_name='seth', 'tom')
game.vote_tally
game.status

# Game over
game.advance_time
game.status
game.players['tom'].dead?
game.winner
