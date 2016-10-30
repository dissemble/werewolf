module Werewolf
  module Commands
    class Start < SlackRubyBot::Commands::Base
      command 'guard' do |client, data, match|
        name = Util::SlackParser.extract_username(match['expression'])
        Game.instance.guard(bodyguard_name: data.user, target: name)
      end
    end
  end
end
