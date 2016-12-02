module Werewolf
  module Commands
    class Join < SlackRubyBot::Commands::Base
      command 'leave' do |_client, data, _match|
        human_name = Werewolf::SlackBot.instance().get_user(data.user)
        Game.instance.leave(human_name)
      end
    end
  end
end
