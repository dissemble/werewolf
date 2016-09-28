module Werewolf
  module Commands
    class Vote < SlackRubyBot::Commands::Base
      command 'vote' do |client, data, match|
        # puts '**** vote ****'
        # puts "client: #{client}"
        # puts "data: #{data}"
        # puts "data.user: #{data.user}"
        # puts "match: #{match}"
        # puts "match['bot']:  #{match['bot']}"
        # puts "match['command']:  #{match['command']}"
        # puts "match['expression']:  #{match['expression']}"        
        # puts '........'

        game = Game.instance
        game.process_vote(data.user, match['expression'], client, data.channel)
      end
    end
  end
end