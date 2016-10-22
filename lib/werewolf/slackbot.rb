require 'slack-ruby-bot'

module Werewolf
  class SlackBot < SlackRubyBot::Server

    # handy for testing with players that aren't real slack users
    attr_accessor :replace_names_with_handles

    def initialize(args)
      @replace_names_with_handles = true
      super args
    end

    # This receives notifications from a Game instance upon changes.
    # Game is Observable, and the slackbot is an observer.  
    def update(options = {})
      send("handle_#{options[:action]}", options.tap { |hsh| hsh.delete(:action) })
    end


    def handle_advance_time(options = {})
      tell_all(options[:message])
    end


    def handle_join(options = {})
      tell_all("#{slackify(options[:player])} #{options[:message]}")
    end


    def handle_join_error(options = {})
      tell_all("#{slackify(options[:player])} #{options[:message]}")
    end


    def handle_status(options = {})
      tell_all("#{options[:message]}.  #{format_players(options[:players])}")
    end


    def handle_start(options = {})
      # TODO:  this should be passing a player and use slackify
      tell_all("<@#{options[:start_initiator]}> #{options[:message]}")
    end


    def handle_tell_player(options = {})
      # puts "tell_player(#{options[:player]}, #{options[:message]})"
      tell_player(options[:player], options[:message])
    end


    def handle_tell_all(options = {})
      tell_all(options[:message])
    end


    def handle_vote(options = {})
      tell_all("#{slackify(options[:voter])} #{options[:message]} #{slackify(options[:votee])}")
    end


    def handle_kill_player(options = {})
      tell_all("#{options[:message]} #{slackify(options[:player])}")
    end


    def tell_all(message)
      puts "tell_all:  #{message}"
      client.say(text: message, channel: 'G2FQMNAF8')
    end


    def tell_player(player, message)
      im = client.web_client.im_open(:user => "#{player.name}")
      client.say(text: message, channel: "#{im.channel.id}")
    end


    def format_players(players)
      if players.empty?
        "Zero players.  Type 'wolfbot join' to join the game."
      else
        "Players: " + players.to_a.map{|p| "#{slackify(p)}" }.join(", ")
      end
    end

    def slackify(player)
      if replace_names_with_handles
        "<@#{player.name}>"
      else
        player.name
      end
    end


	end
end