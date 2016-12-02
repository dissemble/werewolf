module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'end' do |_client, data, _match|
        human_name = Werewolf::SlackBot.instance().get_user(data.user)
        Game.instance.end_game(human_name)
      end
    end
  end
end
