module Werewolf
  module Commands
    class Vote < SlackRubyBot::Commands::Base
      command 'kill' do |_client, data, match|
        name = Util::SlackParser.extract_username(match['expression'])
        Game.instance.nightkill(werewolf: data.user, victim: name)
      end
    end
  end
end
