module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'start' do |client, data, _match|
        # #TODO copy paste debug
        # puts '**** start ****'
        # puts "client: #{client}"
        # puts "data: #{data}"
        # puts "data.user: #{data.user}"
        # puts "match: #{match}"
        # puts "match['bot']:  #{match['bot']}"
        # puts "match['command']:  #{match['command']}"
        # puts "match['expression']:  #{match['expression']}"        
        # puts '........'


        game = Game.instance
        game.process_start(data.user, client, data.channel)
      end
    end
  end
end