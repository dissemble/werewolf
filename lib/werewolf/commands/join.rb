module Werewolf
  module Commands
    class Join < SlackRubyBot::Commands::Base
      command 'join' do |client, data, _match|

        game = Game.instance
        game.process_join(data.user, client, data.channel)
      end
    end
  end
end