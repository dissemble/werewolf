module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'claims' do |_client, _data, _match|
        Game.instance.print_claims
      end
    end
  end
end
