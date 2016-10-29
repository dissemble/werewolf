module Werewolf
  module Commands
    class Vote < SlackRubyBot::Commands::Base
      command 'vote' do |client, data, match|
        name = Util::SlackParser.extract_username(match['expression'])
        Game.instance.vote(data.user, name)
      end
    end
  end
end
