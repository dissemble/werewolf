#paste into 'bundle exec bin/console' session

if ENV['SLACK_API_TOKEN'].nil?
  puts "ERROR:  Please set the 'SLACK_API_TOKEN' environment variable and try again"
  exit(1)
end

channel = ENV['SLACK_CHANNEL']
if channel.nil?
  channel = 'G2FQMNAF8' # werewolf-bot-dev
  # channel = 'C2EP92WF3' # werewolf
end

SlackRubyBot::Client.logger.level = Logger::WARN
game = Werewolf::Game.instance

slackbot = Werewolf::SlackBot.new(token: ENV['SLACK_API_TOKEN'], aliases: ['!', 'w'])
slackbot.channel = channel
game.add_observer(slackbot)
slackbot.start_async

event_loop = Werewolf::EventLoop.new(game)

game.notify_all("SHALL WE PLAY A GAME?")


sleep 2


seer = Werewolf::Player.new(:name => 'bill', :bot => true)
wolf = Werewolf::Player.new(:name => 'tom', :bot => true)
beholder = Werewolf::Player.new(:name => 'wesley', :bot => true)
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
game.vote(voter_name: 'bill', candidate_name: 'john')
game.vote(voter_name: 'tom', candidate_name: 'john')
game.vote(voter_name: 'wesley', candidate_name: 'bill')
game.vote(voter_name: 'john', candidate_name: 'tom')
#villager3 doesn't vote
game.vote_tally
game.remaining_votes
game.status

# Night 1
game.advance_time
game.players['john'].dead?
seer.view(wolf)
game.nightkill(werewolf: 'tom', victim: 'monty')
game.players['monty'].dead?
game.status

# Day 2
game.advance_time
game.players['monty'].dead?

game.vote(voter_name: 'bill', candidate_name: 'tom')
game.vote(voter_name: 'tom', candidate_name: 'bill')
game.vote(voter_name: 'wesley', candidate_name: 'tom')
game.vote_tally
game.remaining_votes
game.status

# Game over
game.advance_time
game.status
game.players['tom'].dead?
game.winner
