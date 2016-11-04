module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'roles' do |_client, data, _match|
        Game.instance.print_roles data.user
      end
    end
  end
end
