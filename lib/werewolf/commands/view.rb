module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'view' do |client, data, match|
        name = Util::SlackParser.extract_username(match['expression'])
        Game.instance.view(seer=data.user, target=name)
      end
    end
  end
end
