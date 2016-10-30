module Werewolf
  module Commands
    class Vote < SlackRubyBot::Commands::Base
      command 'vote' do |_client, data, match|
        name = Util::SlackParser.extract_username(match['expression'])
        Game.instance.vote(voter_name: data.user, candidate_name: name)
      end
    end
  end
end
