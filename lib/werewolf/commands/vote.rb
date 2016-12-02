module Werewolf
  module Commands
    class Vote < SlackRubyBot::Commands::Base
      command 'vote' do |_client, data, match|
        candidate_slack_id = Util::SlackParser.extract_username(match['expression'])
        candidate_human_name = Werewolf::SlackBot.instance().get_user(candidate_slack_id)
        voter_human_name = Werewolf::SlackBot.instance().get_user(data.user)

        Game.instance.vote(voter_name: voter_human_name, candidate_name: candidate_human_name)
      end
    end
  end
end
