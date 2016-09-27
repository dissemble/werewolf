module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'start' do |client, data, match|
        #TODO copy paste debug
        puts '**** start ****'
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

        begin
          game.start

          # ack command
          client.say(text: "<@#{data.user}> has started the game", channel: data.channel)

          # give current game status
          client.say(text: "#{game.format_status}", channel: data.channel)

          # message time period
          client.say(text: "[Dawn]", channel: data.channel)
        rescue RuntimeError => err
          # spit error out in slack
          client.say(text: "#{err.message}", channel: data.channel)
        end
      end
    end
  end
end