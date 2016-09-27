module Werewolf
  module Commands
    class Join < SlackRubyBot::Commands::Base
      command 'join' do |client, data, match|
        #TODO copy paste debug
        puts '**** join ****'
        puts "client: #{client}"
        puts "data: #{data}"
        puts "data.user: #{data.user}"
        puts "match: #{match}"
        puts "match['bot']:  #{match['bot']}"
        puts "match['command']:  #{match['command']}"
        puts "match['expression']:  #{match['expression']}"        
        puts '........'


        # TODO:  gross
        game = Game.instance
        game.join Player.new(data.user)

        puts game.players

        # ack command
        client.say(text: "<@#{data.user}> has joined the game", channel: data.channel)

        # give current game status
        client.say(text: "#{game.format_status}", channel: data.channel)
      end
    end
  end
end