module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'end' do |client, data, _match|
        Game.instance.end_game(data.user)
      end
    end
  end
end
