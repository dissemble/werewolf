require 'slack-ruby-bot'

module Werewolf
  class SlackBot < SlackRubyBot::Server

    def tell_all(message)
      # puts "tell_all:  #{message}"
      client.say(text: message, channel: 'G2FQMNAF8')
    end


    def tell_player()
      # TODO:  implement me
    end


    def handle_advance_time(options = {})
      tell_all(options[:message])
    end


    def handle_join(options = {})
      tell_all("<@#{options[:player].name}> #{options[:message]}")
    end


    def handle_join_error(options = {})
      tell_all(options[:message])
    end


    def update(options = {})
      # puts "update #{options}"
      send("handle_#{options[:action]}", options.tap { |hsh| hsh.delete(:action) })
    end

	end
end