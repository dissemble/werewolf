module Werewolf
  module Commands
    class Status < SlackRubyBot::Commands::Base
      command 'status' do |client, data, _match|
        Game.instance.process_status(client, data.channel)
      end
    end
  end
end
