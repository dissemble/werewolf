module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'start' do |client, data, _match|
        Game.instance.start(data.user)
      end
    end
  end
end
