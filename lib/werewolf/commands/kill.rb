module Werewolf
  module Commands
    class Vote < SlackRubyBot::Commands::Base
      command 'kill' do |_client, data, match|
        victim_slack_id = Util::SlackParser.extract_username(match['expression'])
        victim_human_name = Werewolf::SlackBot.instance().get_user(victim_slack_id)
        wolf_human_name = Werewolf::SlackBot.instance().get_user(data.user)
        
        Game.instance.nightkill(werewolf_name: wolf_human_name, victim_name: victim_human_name)
      end
    end
  end
end
