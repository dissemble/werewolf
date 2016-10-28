require 'slack-ruby-bot'

module Werewolf
  class SlackBot < SlackRubyBot::Server

    def slackbot_channel
      werewolf_bot_dev_channel = 'G2FQMNAF8'
      # werewolf_channel = 'C2EP92WF3'
    end

    # This receives notifications from a Game instance upon changes.
    # Game is Observable, and the slackbot is an observer.  
    def update(options = {})
      send("handle_#{options[:action]}", options.tap { |hsh| hsh.delete(:action) })
    end


    def handle_advance_time(options = {})
      tell_all options[:message]
    end


    def handle_join(options = {})
      tell_all "#{slackify(options[:player])} #{options[:message]}"
    end


    def handle_join_error(options = {})
      tell_all "#{slackify(options[:player])} #{options[:message]}"
    end


    def handle_leave(options = {})
      tell_all "#{slackify(options[:player])} has left the game"
    end


    def handle_status(options = {})
      tell_all "#{options[:message]}\n#{format_players(options[:players])}"
    end


    def handle_view(options = {})
      tell_player options[:viewer], "#{slackify(options[:viewee])} #{options[:message]}"
    end


    def handle_behold(options = {})
      tell_player options[:beholder], "#{options[:message]} #{slackify(options[:seer])}"
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

      tell_all message
    end


    def handle_reveal_wolves(options = {})
      wolves = options[:wolves]
      grammar = (wolves.size == 1) ? 'wolf is' : 'wolves are'
      slackified_wolves = wolves.map{|p| slackify(p)}.join(" and ")
      tell_player options[:player], "The #{grammar} #{slackified_wolves}"
    end


    def handle_start(options = {})
      formatted_roles = options[:active_roles].join(', ')

      # TODO:  this should be passing a player and use slackify
      tell_all "<@#{options[:start_initiator]}> has started the game.  Active roles: [#{formatted_roles}]\n" \
        "```" \
        "beholder:  team good.  knows the identity of the seer.\n" \
        "cultist:   team evil.  knows the identity of the wolves.\n" \
        "seer:      team good.  views the alignment of one player each night.\n" \
        "villager:  team good.  no special powers.\n" \
        "wolf:      team evil.  kills people at night.\n" \
        "```"
    end


    def handle_nightkill(options = {})
      player = options[:player]
      tell_all "***** #{slackify(player)} (#{player.role}) #{options[:message]}"
    end


    def handle_end_game(options = {})
      tell_all "***** #{slackify(options[:player])} #{options[:message]}"
    end


    def handle_tell_player(options = {})
      tell_player options[:player], options[:message]
    end


    def handle_tell_all(options = {})
      tell_all options[:message]
    end


    def handle_vote(options = {})
      tell_all "#{slackify(options[:voter])} #{options[:message]} #{slackify(options[:votee])}"
    end


    def tell_all(message)
      puts "tell_all:  #{message}"
      client.say(text: message, channel: 'G2FQMNAF8')
    end


    def tell_player(player, message)
      puts "tell_player:  #{player.name}, #{message}"
      tell_player options[:player], options[:message]
    end


    def handle_tell_all(options = {})
      tell_all options[:message]
    end


    def handle_vote(options = {})
      tell_all "#{slackify(options[:voter])} #{options[:message]} #{slackify(options[:votee])}"
    end


    def handle_lynch_player(options = {})
      tell_all "***** #{options[:message]} #{slackify(options[:player])} (#{options[:player].role})"
    end


    def handle_help(options = {})
      message = <<MESSAGE
Commands you can use:
```
help:     this command.  'wolfbot help'
join:     join the game.  'wolfbot join' (only before the game starts)
leave:    leave the game.  'wolfbot leave' (only before the game starts)
start:    start the game.  'wolfbot start' (only after players have joined)
end:      terminate the running game.  'wolfbot end'
status:   should probably work...  'wolfbot status'
tally:    show lynch-vote tally (only during day)
kill:     as a werewolf, nightkill a player.  'wolfbot kill @name' (only at night).  
view:     as the seer, reveals the alignment of another player.  'wolfbot see @name' (only at night).  
vote:     vote to lynch a player.  'wolfbot vote @name' (only during day)
claim:    register a claim.  'wolfbot claim i am the walrus'
claims:   view all claims.  'wolfbot claims'
```
MESSAGE

      tell_player options[:player], message

    end


    def handle_game_results(options = {})
      message = options[:message]
      options[:players].each do |name,player|
        line = player.dead? ? '-' : "+"
        line.concat " #{slackify(player)}: #{player.role}\n"
        message.concat line
      end
      tell_all message
    end


    def handle_claims(options = {})
      puts options[:claims]
      message = "Claims:\n"
      options[:claims].each do |player, claim|
        formatted_player = slackify(player)
        formatted_claim = claim || '-'
        message.concat "#{formatted_player}:  #{formatted_claim}\n"
      end

      tell_all message
    end


    def tell_all(message)
      puts "tell_all:  #{message}"

      client.say(text: message, channel: slackbot_channel)
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
        # dead = players.to_a.find_all{|p| p.dead?}
        living = players.to_a.find_all{|p| p.alive?}

        # dead_string = dead.map{|p| "#{slackify(p)}" }.join(", ")
        living_string = living.map{|p| "#{slackify(p)}" }.join(", ")

        # "Dead: [#{dead_string}]  Living: [#{living_string}]"
        "Survivors: [#{living_string}]"
      end
    end
    

    def slackify(player)
      if player.nil?
        ''
      elsif player.bot?
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