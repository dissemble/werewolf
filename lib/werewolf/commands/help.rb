module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'help' do |client, data, _match|
        Game.instance.help(data.user)
      end
    end
  end
end
