require 'set'
require 'observer'

module Werewolf

  class Game
    include Observable

    attr_reader :players
    attr_accessor :active_roles, :day_number, :time_period


    def initialize()
      @active = false
      @players = Hash.new
      @active_roles = nil
      @time_period_generator = create_time_period_generator
      @time_period, @day_number = @time_period_generator.next
      @vote_tally = {} # voted => list of voters
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
      elsif @players.has_key? player.name
        changed
        notify_observers(
          :action => 'join_error', 
          :player => player,
          :message => 'you already joined!')
      else
        @players[player.name] = player
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
        @players.values.each do |player|
          changed
          notify_observers(:action => 'tell_player', :player => player, :message => "boom")
        end
      end
    end


    def vote(voter_name, candidate_name)
      unless @players.has_key? candidate_name
        raise RuntimeError.new("'#{candidate_name}' is not a player.  You may only vote for players")
      end

      unless @players.has_key? voter_name
        raise RuntimeError.new("'#{voter_name}' is not a player.  Only players may vote")
      end

      if @vote_tally.has_key? candidate_name
        @vote_tally[candidate_name] << voter_name
      else
        @vote_tally[candidate_name] = [voter_name]
      end

      changed
      notify_observers(
        :action => 'vote', 
        :voter => @players[voter_name], 
        :votee => @players[candidate_name],
        :message => "voted for")
    end


    def tally
      @vote_tally
    end


    def lynch
      unless @vote_tally.empty?
        # this gives the voters for the player with the most votes
        lynchee_name, voters = @vote_tally.max_by{|k,v| v.size}

        # but there may be a tie.  find anyone with that many voters
        vote_leaders = @vote_tally.select{|k,v| v.size == voters.size}

        if vote_leaders.size > 1
          # tie
        else
          @players[lynchee_name].kill!
        end
      end

      @vote_tally = {}
    end


    def status()
      changed
      notify_observers(:action => 'status', :message => format_time, :players => players.values)
    end


    def format_time
      if active?
        "It is #{time_period} (day #{day_number})"
      else
        "No game running"
      end
    end


    def assign_roles
      @players.values.each do |player|
        player.role = 'wolf'
      end
    end


    def advance_time
      @time_period, @day_number = @time_period_generator.next

      if 'night' == time_period
        message = "[Dusk], day #{day_number}"
        lynch
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

  end

end
