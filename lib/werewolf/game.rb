require 'set'

module Werewolf

  class Game
    attr_reader :players
    attr_accessor :active_roles, :day_number, :time_period

    def initialize()
      @active = false
      @players = Set.new
      @active_roles = nil
      @day_number = 0
      @time_period = nil
    end

    def self.instance()
      @instance ||= Game.new
    end

    def active?()
      @active
    end

    def join(player)
      if active?
        raise ActiveGameError.new(player.name, "New players may not join once the game is active")
      elsif @players.member? player
        raise AlreadyJoinedError.new(player.name, "already joined")
      else
        @players.add(player)
      end
    end

    def start()
      raise "Game is already active" if active?
      raise "Game can't start until there is at least 1 player" if @players.empty?
      assign_roles
      @active = true
    end

    def assign_roles
      @players.each do |player|
        player.role = 'wolf'
      end
    end


    ## TODO:  Slack communication stuff

    def format_players()
      if @players.empty?
        "Zero players.  Type 'wolfbot join' to join the game."
      else
        "Players:  " + @players.to_a.map{|p| "<@#{p.name}>" }.join(", ")
      end
    end

    def format_status()
      if !active?
        "No game running.  #{format_players}"
      else
        "Game is active.  #{format_players}"
      end
    end


    def process_join(username, client, channel)
      player = Player.new(:name => username)

      begin
        join(player)

        ack_message = "<@#{username}> has joined the game"
        communicate(ack_message, client, channel)
        communicate(format_status, client, channel)
      rescue AlreadyJoinedError => err
        communicate("<@#{err.username}> #{err.message}", client, channel)
      rescue ActiveGameError => err
        communicate("<@#{err.username}> you can't join a game after it starts.", client, channel)
      end
    end

    def process_status(client, channel)
      communicate(format_status, client, channel)
    end

    def process_start(username, client, channel)
      begin
        start

        # 'game start' to all
        communicate("<@#{username}> has started the game", client, channel)

        # 'game status' to all
        communicate("<@#{username}> #{format_status}", client, channel)

        # 'game start with role' to each player
        @players.each do |player|
          puts player
          communicate("Game has begun.  Your role is: #{player.role}.", client, "@#{player.name}")
        end

        # 'day start' to all
        communicate("[Dawn]", client, channel)
      rescue RuntimeError => err
        communicate("<@#{username}> #{err.message}.", client, channel)
      end
    end


    def process_vote(voter, votee, client, channel)
      # TODO
      communicate("<@#{voter}> has voted for #{votee}", client, channel)
    end


    def communicate(message, client, channel)
      client.say(text: message, channel: channel)
    end
  end


  class AlreadyJoinedError < StandardError
    attr_reader :username
    def initialize(username, message)
      super(message)
      @username = username
    end
  end


  class ActiveGameError < StandardError
    attr_reader :username
    def initialize(username, message)
      super(message)
      @username = username
    end
  end


end
