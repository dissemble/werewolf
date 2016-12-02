module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'roles' do |_client, data, _match|
        human_name = Werewolf::SlackBot.instance().get_user(data.user)
        Game.instance.print_roles human_name
      end
    end
  end
end
