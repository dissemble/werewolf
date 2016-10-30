module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'start' do |_client, data, _match|
        Game.instance.start(data.user)
      end
    end
  end
end
