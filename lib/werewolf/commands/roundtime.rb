module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'roundtime' do |_client, data, match|
        duration = match['expression']
        puts "duration #{duration}"
        Game.instance.round_time = duration
      end
    end
  end
end