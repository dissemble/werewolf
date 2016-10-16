module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'start' do |client, data, _match|
        # #TODO copy paste debug
        # puts '**** start ****'
        # puts "client: #{client}"
        # puts "data: #{data}"
        # puts "data.user: #{data.user}"
        # puts "data.channel: #{data.channel}"
        # puts "match: #{_match}"
        # puts "match['bot']:  #{_match['bot']}"
        # puts "match['command']:  #{_match['command']}"
        # puts "match['expression']:  #{_match['expression']}"        
        # puts '........'


        Game.instance.start(data.user)
      end
    end
  end
end