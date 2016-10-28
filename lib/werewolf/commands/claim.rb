module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'claim' do |client, data, match|
        # #TODO copy paste debug
        # puts '**** start ****'
        # puts "client: #{client}"
        # puts "data: #{data}"
        # puts "data.user: #{data.user}"
        # puts "data.channel: #{data.channel}"
        # puts "match: #{match}"
        # puts "match['bot']:  #_match['bot']}"
        # puts "match['command']:  #{match['command']}"
        # puts "match['expression']:  #{match['expression']}"        
        # puts '........'

        claim = match['expression']
        Game.instance.claim data.user, claim
      end
    end
  end
end