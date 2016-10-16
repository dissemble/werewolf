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
        notify_observers(
          :action => 'join_error', 
          :player => player, 
          :message => "game is active, joining is not allowed")
      elsif @players.member? player
        changed
        notify_observers(
          :action => 'join_error', 
          :player => player,
          :message => 'you already joined!')
      else
        @players.add(player)
        changed
        notify_observers(:action => 'join', :player => player, :message => "has joined the game")
      end
    end


    def start(start_initiator='Unknown')
      if active?
        changed
        notify_observers(:action => 'tell_all', :message => "Game is already active")
      elsif @players.empty?
        changed
        notify_observers(:action => 'tell_all', :message => "Game can't start until there is at least 1 player")
      else
        assign_roles
        @active = true

        changed
        notify_observers(:action => 'start', :start_initiator => start_initiator, :message => 'has started the game')

        status
        
        # 'game start with role' to each player
        @players.each do |player|
          changed
          notify_observers(:action => 'tell_player', :player => player, :message => "boom")
        end
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

    def process_vote(voter, votee, client, channel)
      # TODO
      communicate("<@#{voter}> has voted for #{votee}", client, channel)
    end


    def communicate(message, client, channel)
      client.say(text: message, channel: channel)
    end
  end

end
