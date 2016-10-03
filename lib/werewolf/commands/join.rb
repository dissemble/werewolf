module Werewolf
  module Commands
    class Join < SlackRubyBot::Commands::Base
      command 'join' do |client, data, _match|
        Game.instance.process_join(data.user, client, data.channel)
      end
    end
  end
end