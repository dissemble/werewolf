#paste into 'bundle exec bin/console' session

SlackRubyBot::Client.logger.level = Logger::INFO
game = Werewolf::Game.instance

slackbot = Werewolf::SlackBot.new(token: ENV['SLACK_API_TOKEN'], aliases: ['fangbot'])
slackbot.replace_names_with_handles = false
game.add_observer(slackbot)

slackbot.start_async


seer = Werewolf::Player.new(:name => 'seer')
wolf = Werewolf::Player.new(:name => 'wolf')
villager1 = Werewolf::Player.new(:name => 'villager1')
villager2 = Werewolf::Player.new(:name => 'villager2')
villager3 = Werewolf::Player.new(:name => 'villager3')


game.join(seer)
game.join(wolf)
game.join(villager1)
game.join(villager2)
game.join(villager3)

# start 5 player game
game.start

# reassign roles
seer.role = 'seer'
wolf.role = 'wolf'
villager1.role = 'villager'
villager2.role = 'villager'
villager3.role = 'villager'

# Night 0
seer.see(villager1)
game.advance_time

# Day 1
game.vote(voter_name='seer', 'villager2')
game.vote(voter_name='wolf', 'villager2')
game.vote(voter_name='villager1', 'seer')
game.vote(voter_name='villager2', 'wolf')
#villager3 doesn't vote
game.tally
game.status
game.winner

# Night 1
game.advance_time
game.players['villager2'].dead?
seer.see(wolf)
game.nightkill('villager3')
game.players['villager3'].dead?
game.status
game.winner

# Day 2
game.advance_time
game.vote(voter_name='seer', 'wolf')
game.vote(voter_name='wolf', 'seer')
game.vote(voter_name='villager1', 'wolf')
game.tally
game.status
game.winner

# Game over
game.advance_time
game.status
game.players['wolf'].dead?
game.winner