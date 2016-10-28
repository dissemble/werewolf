module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'claims' do |client, data, match|
        Game.instance.print_claims
      end
    end
  end
end