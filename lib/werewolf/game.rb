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
      @vote_tally = {} # voted => set of voters
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

        # working around mocking issues
        notify_active_roles

        status
        
        # 'game start with role' to each player
        @players.values.each do |player|
          changed
          notify_observers(
            :action => 'tell_player', 
            :player => player, 
            :message => "Your role is #{player.role}")
        end
      end
    end


    def notify_active_roles
      changed
      role_string = active_roles.join(', ')
      notify_observers(:action => 'tell_all', :message => "active roles:  [#{role_string}]")
    end


    def vote(voter_name=name1, candidate_name=name2)
     unless @players.has_key? voter_name
        raise RuntimeError.new("'#{voter_name}' is not a player.  Only players may vote")
      end

      unless @players.has_key? candidate_name
        raise RuntimeError.new("'#{candidate_name}' is not a player.  You may only vote for players")
      end

      unless @players[candidate_name].alive?
        raise RuntimeError.new("'#{candidate_name}' is not alive.  You may only vote for living players")
      end

      unless 'day' == time_period
        raise RuntimeError.new('you may not vote at night')
      end

      # remove any previous vote
      @vote_tally.each do |k,v| 
        if v.delete?(voter_name) && v.empty?
          @vote_tally.delete(k)
        end
      end


      # add new vote
      if @vote_tally.has_key? candidate_name
        @vote_tally[candidate_name] << voter_name
      else
        @vote_tally[candidate_name] = Set.new([voter_name])
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
          kill_player @players[lynchee_name]
        end
      end

      @vote_tally = {}
    end


    def kill_player(player)
      player.kill!

      changed
      notify_observers(
        :action => 'kill_player',
        :player => player,
        :message => 'With pitchforks in hand, the townsfolk killed')
    end


    def nightkill(name)
      raise RuntimeError.new("no such player as #{name}") unless @players[name]

      @players[name].kill!
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


    def define_roles
      rolesets = {
        1 => ['wolf'],
        2 => ['villager', 'wolf'],
        3 => ['villager', 'villager', 'wolf'],
        4 => ['seer', 'villager', 'villager', 'wolf'],
        5 => ['seer', 'villager', 'villager', 'wolf', 'wolf'],
        6 => ['seer', 'villager', 'villager', 'villager', 'wolf', 'wolf'],
        7 => ['seer', 'villager', 'villager', 'villager', 'villager', 'wolf', 'wolf'],
        8 => ['seer', 'villager', 'villager', 'villager', 'villager', 'wolf', 'wolf', 'wolf'],
        9 => ['seer', 'villager', 'villager', 'villager', 'villager', 'villager', 'wolf', 'wolf', 'wolf'],
        10 => ['seer', 'villager', 'villager', 'villager', 'villager', 'villager', 'villager', 'wolf', 'wolf', 'wolf'],
      }

      available_roles = rolesets[@players.size]
      if available_roles.nil?
        raise RuntimeError.new("no rolesets for #{@players.size} players")
      else
        available_roles
      end
    end


    def assign_roles
      @active_roles = define_roles

      roles_remaining = @active_roles.shuffle(random: Random.new)

      @players.values.each do |player|
        player.role = roles_remaining.pop
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

      if 'night' == time_period
        lynch
      end
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


    def winner
      the_living = players.find_all{|k,v| v.alive?}
      remaining_sides = the_living.map{|k,v| v.team}.uniq

      if remaining_sides.size == 1
        remaining_sides.first
      else
        nil
      end
    end

  end

end
