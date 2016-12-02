module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'help' do |_client, data, _match|
        human_name = Werewolf::SlackBot.instance().get_user(data.user)
        Game.instance.help(human_name)
      end
    end
  end
end
