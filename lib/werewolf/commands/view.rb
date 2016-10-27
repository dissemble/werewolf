module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'view' do |client, data, match|
        # #TODO copy paste debug
        # puts '**** start ****'
        # puts "client: #{client}"
        # puts "data: #{data}"
        # puts "data.user: #{data.user}"
        # puts "data.channel: #{data.channel}"
        # puts "match: #{_match}"
        # puts "match['bot']:  #{_match['bot']}"
        # puts "match['command']:  #{_match['command']}"
        # puts "match['expression']:  #{match['expression']}"        
        # puts '........'

        name = Util::SlackParser.extract_username(match['expression'])
        Game.instance.view(viewer=data.user, viewee=name)
      end
    end
  end
end