module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'claims' do |client, data, match|
        # #TODO copy paste debug
        # puts '**** start ****'
        # puts "client: #{client}"
        # puts "data: #{data}"
        # puts "data.user: #{data.user}"
        # puts "data.channel: #{data.channel}"
        # puts "match: #{match}"
        # puts "match['bot']:  #{match['bot']}"
        # puts "match['command']:  #{match['command']}"
        # puts "match['expression']:  #{match['expression']}"        
        # puts '........'


        Game.instance.print_claims
      end
    end
  end
end