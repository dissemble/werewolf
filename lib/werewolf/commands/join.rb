module Werewolf
  module Commands
    class Join < SlackRubyBot::Commands::Base
      command 'join' do |_client, data, _match|
        Game.instance.add_username_to_game(data.user)
      end
    end
  end
end