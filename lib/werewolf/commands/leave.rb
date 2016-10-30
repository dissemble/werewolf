module Werewolf
  module Commands
    class Join < SlackRubyBot::Commands::Base
      command 'leave' do |_client, data, _match|
        Game.instance.leave(data.user)
      end
    end
  end
end
