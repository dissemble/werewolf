module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'view' do |_client, data, match|
        target_slack_id = Util::SlackParser.extract_username(match['expression'])
        target_human_name = Werewolf::SlackBot.instance().get_user(target_slack_id)
        seer_human_name = Werewolf::SlackBot.instance().get_user(data.user)

        Game.instance.view(seer_name: seer_human_name, target_name: target_human_name)
      end
    end
  end
end
