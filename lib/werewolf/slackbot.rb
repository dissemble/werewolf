require 'slack-ruby-bot'

module Werewolf
  class SlackBot < SlackRubyBot::Server

    # This receives notifications from a Game instance upon changes.
    # Game is Observable, and the slackbot is an observer.  
    def update(options = {})
      send("handle_#{options[:action]}", options.tap { |hsh| hsh.delete(:action) })
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


    def handle_status(options = {})
      tell_all("#{options[:message]}.  #{format_players(options[:players])}")
    end


    def tell_all(message)
      # puts "tell_all:  #{message}"
      client.say(text: message, channel: 'G2FQMNAF8')
    end


    def tell_player()
      # TODO:  implement me
    end


    def format_players(players)
      if players.empty?
        "Zero players.  Type 'wolfbot join' to join the game."
      else
        "Players: " + players.to_a.map{|p| "<@#{p.name}>" }.join(", ")
      end
    end



	end
end