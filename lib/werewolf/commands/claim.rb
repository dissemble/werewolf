module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'claim' do |_client, data, match|
        claim = match['expression']
        human_name = Werewolf::SlackBot.instance().get_user(data.user)
        Game.instance.claim human_name, claim
      end
    end
  end
end
