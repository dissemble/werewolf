module Werewolf
  module Commands
    class Status < SlackRubyBot::Commands::Base
      command 'status' do |_client, _data, _match|
        Game.instance.status()
      end
    end
  end
end
