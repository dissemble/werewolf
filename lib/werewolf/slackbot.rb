require 'slack-ruby-bot'

module Werewolf
  class SlackBot < SlackRubyBot::Server

    def tell_all()
      # TODO:  implement me
    end


    def tell_player()
      # TODO:  implement me
    end


    def advance_time()
      tell_all
    end


    def update(args)
      advance_time
    end
	end
end