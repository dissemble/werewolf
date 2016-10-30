module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'view' do |_client, data, match|
        name = Util::SlackParser.extract_username(match['expression'])
        Game.instance.view(seer_name: data.user, target_name: name)
      end
    end
  end
end
