require 'slack-ruby-bot'

module Werewolf
  class SlackBot < SlackRubyBot::Server
    attr_writer :channel

    ROLE_ICONS = {
      apprentice: ':stopwatch:',
      beholder: ':eyes:',
      bodyguard: ':shield:',
      cultist: ':dagger_knife:',
      golem: ':moyai:',
      lumberjack: ':axe:',
      lycan: ':see_no_evil:',
      sasquatch: ':monkey:',
      seer: ':crystal_ball:',
      tanner: ':snake:',
      villager: ':bust_in_silhouette:',
      wolf: ':wolf:'
    }


    def initialize(options = {})
      super options
      @slack_users = {}
      @@instance = self
    end


    def SlackBot.instance()
      @@instance
    end


    def user(slack_id)
      @slack_users[slack_id]
    end


    def register_user(slack_id)
      @slack_users[slack_id] = get_slack_user_info(slack_id)
    end


    def get_slack_user_info(slack_id)
      response = client.web_client.users_info(user: slack_id)
      response.user
    end


    def SlackBot.format_role role_name
      role_key = role_name.to_sym
      raise InvalidRoleError.new("#{role_name} is not a valid role") unless ROLE_ICONS.has_key? role_key

      "#{ROLE_ICONS.fetch role_key} #{role_name}"
    end


    # This receives notifications from a Game instance upon changes.
    # Game is Observable, and the slackbot is an observer.
    def update(options = {})
      send("handle_#{options[:action]}", options.tap { |hsh| hsh.delete(:action) })
    end


    def handle_dawn(options = {})
      puts 'handle dawn'
      title = <<TITLE
=================
§  [Dawn], day #{options[:day_number]} :sunrise:
=================
TITLE
      message = "The sun will set again in #{options[:round_time]} seconds :hourglass:."
      tell_all(message, title:title)
    end


    def handle_dusk(options = {})
      puts 'handle dusk'
            title = <<TITLE
=================
§  [Dusk], day #{options[:day_number]} :night_with_stars:
=================
TITLE
      message = "The sun will rise again in #{options[:round_time]} seconds :hourglass:."
      tell_all(message, title:title)
    end


    def handle_join(options = {})
      tell_all ":white_check_mark: #{slackify(options[:player])} joins the game", color: "good"
    end


    def handle_join_error(options = {})
      tell_all ":no_entry: #{slackify(options[:player])} #{options[:message]}", color: "danger"
    end


    def handle_leave(options = {})
      tell_all ":leaves: #{slackify(options[:player])} leaves the game", color: "warning"
    end


    def handle_failed_kill(options = {})
      tell_all "#{slackify(options[:player])} survives!!!  A murder attempt fails", color: "warning"
    end


    def handle_status(options = {})
      tell_all("#{options[:message]}\n#{format_players(options[:players])}", title: "Game Status :wolf:")
    end


    def handle_view(options = {})
      tell_player options[:seer], "#{ROLE_ICONS[:seer]} #{slackify(options[:target])} #{options[:message]}"
    end


    def handle_behold(options = {})
      tell_player options[:beholder], "#{options[:message]} #{slackify(options[:seer])} #{ROLE_ICONS[:seer]}"
    end


    def handle_tally(options = {})
      fields = []

      vote_hash = options[:vote_tally]
      if vote_hash.empty?
        tally_message = "No votes yet :zero:"
      else
        lines = vote_hash.map do |candidate, voterset|
          voters = voterset.map{|name| "#{get_name(name)}"}.join(', ')
          "Lynch #{get_name(candidate)}:  (#{pluralize_votes(voterset.size)}) - #{voters}"
        end
        tally_message = lines.join("\n")
      end

      fields.push({title: ':memo: Town Ballot', value: tally_message, short: false})

      remaining_votes = options[:remaining_votes]
      if remaining_votes.empty?
        remaining_message = "Everyone has voted! :ballot_box_with_check:"
      else
        remaining_message = remaining_votes.map{|name| "#{get_name(name)}"}.sort.join(', ')
      end

      fields.push({title: ':hourglass: Remaining Voters', value: remaining_message, short: false})

      tell_all '', fields: fields

    end


    def handle_reveal_wolves(options = {})
      wolves = options[:wolves]
      grammar = (wolves.size == 1) ? 'wolf is' : 'wolves are'
      slackified_wolves = wolves.map{|p| slackify(p)}.join(" and ")
      tell_player options[:player], "#{ROLE_ICONS[:wolf]} The #{grammar} #{slackified_wolves}"
    end


    def handle_start(options = {})
      formatted_roles = options[:active_roles].sort.join(', ')

      all_fields = role_descriptions.delete_if {|k,_v| !options[:active_roles].include?(k)}

      tell_all(
        "Active roles: [#{formatted_roles}]",
        title: "#{slackify(options[:start_initiator])} has started the game. :partyparrot:",
        color: "good",
        fields: all_fields.values
      )
    end


    def handle_roles(options = {})
      formatted_roles = options[:active_roles].sort.join(', ')
      tell_player(options[:player], "Active roles: [#{formatted_roles}]")
    end


    def handle_nightkill(options = {})
      player = options[:player]
      tell_all ":skull_and_crossbones: #{slackify(player)} (#{SlackBot.format_role player.original_role}) #{options[:message]}", title: "Murder!", color: "danger"
    end


    def handle_end_game(options = {})
      tell_all "***** #{slackify(options[:player])} #{options[:message]}"
    end


    def handle_notify_role(options = {})
      player = options[:player]
      message = "Your role is: #{SlackBot.format_role player.role}. #{options[:exhortation]}"
      tell_player player, message
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


    def handle_lynch_player(options = {})
      tell_all "***** #{options[:message]} #{slackify(options[:player])} (#{SlackBot.format_role options[:player].original_role})"
    end


    def handle_help(options = {})
      message = <<MESSAGE
Commands you can use:
```
help:     this command 
          'w help' (DM)
join:     join the game
          'w join' (before the game starts)
leave:    leave the game
          'w leave' (before the game starts)

roundtime:    set the round duration (in seconds) for the next game
          'w roundtime 600'
start:    start the game
          'w start' (only after players have joined)
end:      terminate the running game.  
          'w end'

claim:    register a claim.  
          'w claim i am the walrus'
claims:   view all claims.  
          'w claims'
roles:    show all roles for the current game.  
          'w roles' (DM)
status:   show current game status.  
          'w status'

tally:    show lynch-vote tally 
          'w tally' (only during day)
vote:     vote to lynch a player.
          'w vote @name' (only during day)


guard:    as the bodyguard, protects one player from nightkill.  
          'w guard @name' (DM, only at night)
kill:     as a werewolf, nightkill a player.
          'w kill @name' (DM, only at night).
view:     as the seer, reveals the alignment of another player.
          'w view @name' (DM, only at night).
```
MESSAGE

      tell_player options[:player], message

    end


    def handle_game_results(options = {})
      message = ":tada: #{options[:message]}\n"
      options[:players].each do |_name,player|
        line = player.dead? ? '-' : "+"
        line.concat " #{slackify(player)}: #{SlackBot.format_role player.original_role}"
        if player.dead?
          line.concat " :coffin:"
        end
        line.concat "\n"
        message.concat line
      end
      tell_all message
    end


    def handle_claims(options = {})
      puts options[:claims]
      message = ""
      not_claiming = []
      options[:claims].each do |player, claim|
        if claim.nil?
          not_claiming << slackify(player)
        else
          formatted_player = slackify(player)
          message.concat "#{formatted_player}:  #{claim}\n"
        end
      end

      unless not_claiming.empty?
        no_claims_message = "No claims:  "
        no_claims_message.concat not_claiming.join(', ')
        message.concat no_claims_message
        message.concat "\n"
      end

      tell_all message, title: "Claims :thinking_face:"
    end


    def handle_tell_name(options = {})
      name = options[:name]
      message = options[:message]
      puts "tell_name:  #{name}, #{message}"
      im = client.web_client.im_open(:user => "#{name}")
      client.say(text: message, channel: "#{im.channel.id}", mrkdwn: true)
    end


    def tell_all(message, title: nil, color: nil, fields: nil)
      puts "tell_all('#{message}', title:'#{title}', color:'#{color}'"

      # client.say(text: message, channel: slackbot_channel)
      client.web_client.chat_postMessage(
        channel: @channel,
        as_user: true,
        attachments: [
          {
            fallback: message,
            color: color,
            title: title,
            text: message,
            fields: fields,
            mrkdwn_in: ["text", "fields"]
          }
        ]
      )
    end


    def tell_player(player, message)
      puts "tell_player:  #{player.name}, #{message}"
      unless player.bot?
        im = client.web_client.im_open(:user => "#{player.name}")
        client.say(text: message, channel: "#{im.channel.id}", mrkdwn: true)
      end
    end


    def format_players(players)
      if players.empty?
        "Zero players.  Type `wolfbot join` to join the game."
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
        slack_user = user(player.name)
        if slack_user
          slack_user.name
        else 
          "<@#{player.name}>"
        end
      end
    end


    def get_name(slack_id)
      slack_user = user(slack_id)
      if slack_user
        slack_user.name
      else 
        slack_id
      end
    end


    private


    def role_descriptions
      {
        'apprentice' => {
            title: SlackBot.format_role('apprentice'),
            value: "team good.  starts as a villager, but is promoted to seer if the original seer dies",
            short: true
          },
        'beholder' => {
            title: SlackBot.format_role('beholder'),
            value: "team good.  knows the identity of the seer.",
            short: true
          },
        'bodyguard' => {
            title: SlackBot.format_role('bodyguard'),
            value: "team good.  protects one player from the wolves each night.",
            short: true
          },
        'cultist' => {
            title: SlackBot.format_role('cultist'),
            value: "team evil.  knows the identity of the wolves.",
            short: true
          },
        'golem' => {
            title: SlackBot.format_role('golem'),
            value: "team good.  immune to nightkills.",
            short: true
          },
        'lumberjack' => {
            title: SlackBot.format_role('lumberjack'),
            value: "team good.  a brawny villager who will survive the first attempt on his life.",
            short: true
          },
        'lycan' => {
            title: SlackBot.format_role('lycan'),
            value: "team good, but appears evil to seer.  no special powers.",
            short: true
          },
        'sasquatch' => {
            title: SlackBot.format_role('sasquatch'),
            value: "starts on team good, but if there is ever a day without a lynch, he becomes a wolf.",
            short: true
          },
        'seer' => {
            title: SlackBot.format_role('seer'),
            value: "team good.  views the alignment of one player each night.",
            short: true
          },
        'tanner' => {
            title: SlackBot.format_role('tanner'),
            value: "team good.  if lynched on day 1, tanner wins and everyone else loses.",
            short: true
          },
        'villager' => {
            title: SlackBot.format_role('villager'),
            value: "team good.  no special powers.",
            short: true
          },
        'wolf' => {
            title: SlackBot.format_role('wolf'),
            value: "team evil.  kills people at night.",
            short: true
          }
        }
    end


    def pluralize_votes(number)
      if number == 1
        "1 vote"
      else
        "#{number} votes"
      end
    end

  end
end
