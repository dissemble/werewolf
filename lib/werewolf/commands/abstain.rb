module Werewolf
  module Commands
    class Abstain < SlackRubyBot::Commands::Base
      command 'abstain' do |_client, data, match|
        Game.instance.abstain(voter_name: data.user)
      end
    end
  end
end
