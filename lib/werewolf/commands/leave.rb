module Werewolf
  module Commands
    class Join < SlackRubyBot::Commands::Base
      command 'leave' do |_client, data, _match|
        #TODO copy paste debug
        # puts '**** start ****'
        # puts "_client: #{_client}"
        # puts "data: #{data}"
        # puts "data.user: #{data.user}"
        # puts "data.channel: #{data.channel}"
        # puts "_match: #{_match}"
        # puts "_match['bot']:  #{_match['bot']}"
        # puts "_match['command']:  #{_match['command']}"
        # puts "_match['expression']:  #{_match['expression']}"        
        # puts '........'
        Game.instance.leave(data.user)
      end
    end
  end
end