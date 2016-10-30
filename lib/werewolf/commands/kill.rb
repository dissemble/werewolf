module Werewolf
  module Commands
    class Vote < SlackRubyBot::Commands::Base
      command 'kill' do |_client, data, match|
        name = Util::SlackParser.extract_username(match['expression'])
        Game.instance.nightkill(werewolf_name: data.user, victim_name: name)
      end
    end
  end
end
