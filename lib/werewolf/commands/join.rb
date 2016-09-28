module Werewolf
  module Commands
    class Join < SlackRubyBot::Commands::Base
      command 'join' do |client, data, match|
        # puts '**** join ****'
        # puts "client: #{client}"
        # puts "data: #{data}"
        # puts "data.user: #{data.user}"
        # puts "match: #{match}"
        # puts "match['bot']:  #{match['bot']}"
        # puts "match['command']:  #{match['command']}"
        # puts "match['expression']:  #{match['expression']}"        
        # puts '........'

        game = Game.instance
        game.process_join(data.user, client, data.channel)
      end
    end
  end
end