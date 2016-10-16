require 'set'
require 'observer'

module Werewolf

  class Game
    include Observable

    attr_reader :players
    attr_accessor :active_roles, :day_number, :time_period


    def initialize()
      @active = false
      @players = Set.new
      @active_roles = nil
      @time_period_generator = create_time_period_generator
      @time_period, @day_number = @time_period_generator.next
    end

    def self.instance()
      @instance ||= Game.new
    end


    def active?()
      @active
    end


    def add_username_to_game(name)
      join(Player.new(:name => name))
    end


    def join(player)
      if active?
        changed
        notify_observers(:action => 'join_error', :message => "New players may not join once the game is active")
      elsif @players.member? player
        changed
        notify_observers(:action => 'join_error', :message => 'Player already joined')
      else
        @players.add(player)
        changed
        notify_observers(:action => 'join', :player => player, :message => "has joined the game")
      end
    end


    def start(start_initiator='Unknown')
      raise "Game is already active" if active?
      raise "Game can't start until there is at least 1 player" if @players.empty?
      assign_roles
      @active = true

      changed
      notify_observers(:action => 'start', :start_initiator => start_initiator, :message => 'has started the game')

      status
      
      # 'game start with role' to each player
      @players.each do |player|
        changed
        notify_observers(:action => 'tell', :player => player, :message => "boom")
      end
    end


    def status()
      changed
      notify_observers(:action => 'status', :message => format_time, :players => players)
    end


    def format_time
      if active?
        "It is #{time_period} (day #{day_number})"
      else
        "No game running"
      end
    end


    # TODO: kill
    def format_status()
      if !active?
        "No game running.  #{format_players}"
      else
        "Game is active.  #{format_players}"
      end
    end

    # TODO: kill
    def format_players()
      if @players.empty?
        "Zero players.  Type 'wolfbot join' to join the game."
      else
        "Players:  " + @players.to_a.map{|p| "<@#{p.name}>" }.join(", ")
      end
    end


    def assign_roles
      @players.each do |player|
        player.role = 'wolf'
      end
    end


    def advance_time
      @time_period, @day_number = @time_period_generator.next

      if 'night' == time_period
        message = "[Dusk], day #{day_number}"
      else
        message = "[Dawn], day #{day_number}"
      end

      changed
      notify_observers(:action => 'advance_time', :message => message)
    end


    def create_time_period_generator
      Enumerator.new do |yielder|
        times = ['night', 'day']
        i = 0
        loop do
          day = (i+1) / 2
          yielder.yield [times[i%2], day]
          i += 1
        end
      end
    end



    ## TODO:  Slack communication stuff

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

end
