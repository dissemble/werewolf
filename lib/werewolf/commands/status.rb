module Werewolf
  module Commands
    class Status < SlackRubyBot::Commands::Base
      command 'status' do |client, data, _match|
        Game.instance.status()
      end
    end
  end
end
