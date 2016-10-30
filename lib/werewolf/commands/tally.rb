module Werewolf
  module Commands
    class Join < SlackRubyBot::Commands::Base
      command 'tally' do |_client, _data, _match|
        Game.instance.print_tally
      end
    end
  end
end
