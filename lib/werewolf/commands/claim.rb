module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'claim' do |_client, data, match|
        claim = match['expression']
        Game.instance.claim data.user, claim
      end
    end
  end
end
