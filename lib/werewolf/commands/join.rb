module Werewolf
  module Commands
    class Join < SlackRubyBot::Commands::Base
      command 'join' do |_client, data, _match|
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
        Game.instance.add_username_to_game(data.user)
      end
    end
  end
end
