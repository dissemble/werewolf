require 'slack-ruby-bot'

module Werewolf

  class SlackBot < SlackRubyBot::Bot
    command 'debug' do |client, data, match|
      puts '********'
      puts client
      puts data
      puts match
      puts match['bot']
      puts match['command']
      puts match['expression']
      puts '........'

      client.say(text: "#{match['command']} processed <@U0BGR4GF8>", channel: data.channel)
    end

    operator '=' do |client, data, match|
      puts '********'
      puts client
      puts data
      puts match

      # implementation detail
      client.say(text: 'sup', channel: data.channel)
    end
  end
  
end