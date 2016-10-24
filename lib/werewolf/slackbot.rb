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
      tell_all("#{slackify(options[:player])} #{options[:message]}")
    end


    def handle_join_error(options = {})
      tell_all("#{slackify(options[:player])} #{options[:message]}")
    end


    def handle_status(options = {})
      tell_all("#{options[:message]}.  #{format_players(options[:players])}")
    end


    def handle_view(options = {})
      tell_player(options[:viewer], "#{slackify(options[:viewee])} #{options[:message]}")
    end


    def handle_behold(options = {})
      tell_player(options[:beholder], "#{options[:message]} #{slackify(options[:seer])}")
    end


    def handle_tally(options = {})
      vote_hash = options[:vote_tally]

      if vote_hash.empty?
        message = "No votes yet"
      else
        lines = vote_hash.map do |k, v|
          voters = v.map{|name| "<@#{name}>"}.join(', ')
          "Lynch <@#{k}>:  (#{pluralize_votes(v.size)}) - #{voters}"
        end
        message = lines.join("\n")
      end

      tell_all(message)
    end


    def handle_start(options = {})
      # TODO:  this should be passing a player and use slackify
      tell_all("<@#{options[:start_initiator]}> #{options[:message]}")
    end


    def handle_nightkill(options = {})
      tell_all("***** #{slackify(options[:player])} #{options[:message]}")
    end


    def handle_end_game(options = {})
      tell_all("***** #{slackify(options[:player])} #{options[:message]}")
    end


    def handle_tell_player(options = {})
      tell_player(options[:player], options[:message])
    end


    def handle_tell_all(options = {})
      tell_all(options[:message])
    end


    def handle_vote(options = {})
      tell_all("#{slackify(options[:voter])} #{options[:message]} #{slackify(options[:votee])}")
    end


    def tell_all(message)
      puts "tell_all:  #{message}"
      client.say(text: message, channel: 'G2FQMNAF8')
    end


    def tell_player(player, message)
      puts "tell_player:  #{player.name}, #{message}"
      tell_player(options[:player], options[:message])
    end


    def handle_tell_all(options = {})
      tell_all(options[:message])
    end


    def handle_vote(options = {})
      tell_all("#{slackify(options[:voter])} #{options[:message]} #{slackify(options[:votee])}")
    end


    def handle_lynch_player(options = {})
      tell_all("***** #{options[:message]} #{slackify(options[:player])}")
    end


    def handle_game_results(options = {})
      message = options[:message]
      options[:players].each do |name,player|
        line = player.dead? ? '-' : "+"
        line.concat " #{name}: #{player.role}\n"
        message.concat line
      end
      tell_all(message)
    end


    def tell_all(message)
      puts "tell_all:  #{message}"

      werewolf_bot_dev_channel = 'G2FQMNAF8'
      werewolf_channel = 'C2EP92WF3'
      client.say(text: message, channel: werewolf_channel)
    end


    def tell_player(player, message)
      puts "tell_player:  #{player.name}, #{message}"
      unless player.bot?
        im = client.web_client.im_open(:user => "#{player.name}")
        client.say(text: message, channel: "#{im.channel.id}")
      end
    end


    def format_players(players)
      if players.empty?
        "Zero players.  Type 'wolfbot join' to join the game."
      else
        dead = players.to_a.find_all{|p| p.dead?}
        living = players.to_a.find_all{|p| p.alive?}

        dead_string = dead.map{|p| "#{slackify(p)}" }.join(", ")
        living_string = living.map{|p| "#{slackify(p)}" }.join(", ")

        "Dead: [#{dead_string}]  Living: [#{living_string}]"
      end
    end
    

    def slackify(player)
      if player.bot?
        player.name
      else
        "<@#{player.name}>"
      end
    end

    private

    def pluralize_votes(number)
      if number == 1
        "1 vote"
      else
        "#{number} votes"
      end
    end

	end
end