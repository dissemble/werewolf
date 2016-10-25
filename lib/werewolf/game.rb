require 'set'
require 'observer'

module Werewolf

  class Game
    include Observable

    attr_reader :players
    attr_accessor :active_roles, :day_number, :night_actions, :time_period
    attr_accessor :time_remaining_in_round, :vote_tally

    def initialize()
      reset
    end


    def reset
      @players = Hash.new
      @active = false
      @active_roles = nil
      @time_period_generator = create_time_period_generator
      @time_period, @day_number = @time_period_generator.next
      @vote_tally = {} 
      @night_actions = {}
      @time_remaining_in_round = default_time_remaining_in_round
    end


    def default_time_remaining_in_round
      120
    end


    def self.instance()
      @instance ||= Game.new
    end


    def active?
      @active
    end


    def add_username_to_game(name)
      join(Player.new(:name => name))
    end


    def join(player)
      if active?
        message = "game is active, joining is not allowed"
        changed
        notify_observers(:action => 'join_error', :player => player, :message => message)
      elsif @players.has_key? player.name
        changed
        notify_observers(:action => 'join_error', :player => player, :message => 'you already joined!')
      else
        @players[player.name] = player
        changed
        notify_observers(:action => 'join', :player => player, :message => "has joined the game")
      end
    end


    def start(start_initiator='Unknown')
      if active?
        notify_all("Game is already active")
      elsif @players.empty?
        notify_all("Game can't start until there is at least 1 player")
      else
        assign_roles
        @active = true

        notify_start(start_initiator)
        status
        
        @players.values.each do |player|
          notify_player_of_role(player)
        end 
      end
    end


    def notify_start(start_initiator)
      active_role_string = active_roles.join(', ')
      message = "has started the game.  Active roles: [#{active_role_string}]"
      changed
      notify_observers(:action => 'start', :start_initiator => start_initiator, :message => message)
    end


    def notify_player_of_role(player)
      message = "Your role is: #{player.role}"
      changed
      notify_observers(:action => 'tell_player', :player => player, :message => message)

      if 'beholder' == player.role
        behold(player)
      end
    end


    def behold(beholder)
      seer = @players.values.find{|p| p.role == 'seer'}
      changed
      notify_observers(:action => 'behold', :beholder => beholder, :seer => seer, :message => 'The seer is:')
    end



    def end_game(name='Unknown')
      raise RuntimeError.new('Game is not active') unless active?

      ender = @players[name]

      changed
      notify_observers(:action => 'end_game', :player => ender, :message => 'ended the game')

      print_results
      reset
    end


    def print_tally
      changed
      notify_observers(:action => 'tally', :vote_tally => vote_tally)
    end


    def notify_of_active_roles
      role_string = active_roles.join(', ')
      notify_all("active roles:  [#{role_string}]")
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
        message = "You may not vote at night.  Night ends in #{time_remaining_in_round} seconds"
        notify_all(message)
        raise RuntimeError.new(message)
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

      print_tally
      
      if voting_finished?
        notify_all "All votes have been cast - lynch will happen early."
        advance_time 
      end
    end


    def voting_finished?
      (living_players.size == vote_count)
    end


    def detect_voting_finished?
      (living_players.size == vote_count)
    end


    def vote_count
      @vote_tally.values.reduce(0) {|count, s| count += s.size}
    end


    def living_players
      players.values.find_all{|p| p.alive?}
    end


    def lynch
      if @vote_tally.empty?
        notify_all("No one voted - no one was lynched")
      else
        # this gives the voters for the player with the most votes
        lynchee_name, voters = @vote_tally.max_by{|k,v| v.size}

        # but there may be a tie.  find anyone with that many voters
        vote_leaders = @vote_tally.select{|k,v| v.size == voters.size}

        if vote_leaders.size > 1
          # tie
          notify_all("The townsfolk couldn't decide - no one was lynched")
        else
          lynch_player @players[lynchee_name]
        end
      end

      @vote_tally = {}
    end


    def lynch_player(player)
      player.kill!

      changed
      notify_observers(
        :action => 'lynch_player',
        :player => player,
        :message => 'With pitchforks in hand, the townsfolk killed')
    end


    def nightkill(werewolf=name1, victim=name2)
      wolf_player = @players[werewolf]
      victim_player = @players[victim]
      raise RuntimeError.new("no such player as #{victim}") unless victim_player
      raise RuntimeError.new('Only players may nightkill') unless wolf_player
      raise RuntimeError.new('Only wolves may nightkill') unless wolf_player.role == 'wolf'
      raise RuntimeError.new('nightkill may only be used at night') unless time_period == 'night'

      @night_actions['nightkill'] = lambda {
        victim_player.kill!
        changed
        notify_observers(:action => 'nightkill', :player => victim_player, :message => 'was killed during the night')
      }

      # acknowledge nightkill command
      notify_player(wolf_player, 'Nightkill order acknowledged.  It will take affect at dawn.')
    end


    def view(viewer=name1, viewee=name2)
      viewing_player = @players[viewer]
      viewed_player = @players[viewee]

      raise RuntimeError.new('View is only available to players') unless viewing_player
      raise RuntimeError.new('View is only available to the seer') unless viewing_player.role == 'seer'
      raise RuntimeError.new('Seer must be alive to view') unless viewing_player.alive?
      raise RuntimeError.new('You can only view at night') unless time_period == 'night'
      raise RuntimeError.new('You must view a real player') unless viewed_player

      @night_actions['view'] = lambda {
        team = viewing_player.view(viewed_player)
        changed
        notify_observers(
          :action => 'view', 
          :viewer => viewing_player, 
          :viewee => viewed_player,
          :message => "is on the side of #{team}")
      }

      notify_player(viewing_player, "View order acknowledged.  It will take affect at dawn.")
    end


    def help(name)
      player = Player.new(:name => name)

      message = <<MESSAGE
Commands you can use:
help:   this command
join:   join the game (only before the game starts)
start:  start the game (only after players have joined)
end:    terminate running game
status: should probably work...
tally:  show lynch-vote tally (only during day)
kill:   as a werewolf, nightkill a player.  (only at night)
view:   as the seer, reveals the alignment of another player.  (only at night)
vote:   vote to lynch a player.  (only during day)

MESSAGE

      changed
      notify_observers(
        :action => 'tell_player', 
        :player => player, 
        :message => message)
    end


    def status()
      message = "#{format_time}"

      changed
      notify_observers(:action => 'status', :message => message, :players => players.values)
    end


    def format_time
      if active?
        if time_period == 'night'
          "It is night (day #{day_number}).  The sun will rise again in #{time_remaining_in_round} seconds."
        else
          "It is daylight (day #{day_number}).  The sun will set again in #{time_remaining_in_round} seconds."
        end
      else
        "No game running"
      end
    end


    def define_roles
      rolesets = {
        1 => ['seer'],
        2 => ['seer', 'wolf'],
        3 => ['seer', 'villager', 'wolf'],
        4 => ['seer', 'villager', 'villager', 'wolf'],
        5 => ['seer', 'beholder', 'villager', 'wolf', 'wolf'],
        6 => ['seer', 'beholder', 'villager', 'villager', 'wolf', 'wolf'],
        7 => ['seer', 'beholder', 'villager', 'villager', 'villager', 'wolf', 'wolf'],
        8 => ['seer', 'beholder', 'villager', 'villager', 'villager', 'wolf', 'wolf', 'wolf'],
        9 => ['seer', 'beholder', 'villager', 'villager', 'villager', 'villager', 'wolf', 'wolf', 'wolf'],
        10 => ['seer', 'beholder', 'villager', 'villager', 'villager', 'villager', 'villager', 'wolf', 'wolf', 'wolf'],
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
      @time_remaining_in_round = default_time_remaining_in_round
      @time_period, @day_number = @time_period_generator.next

      if 'night' == time_period
        lynch
      else
        process_night_actions
      end

      if 'night' == time_period
        message = "[Dusk], day #{day_number}.  The sun will rise again in #{default_time_remaining_in_round} seconds."
      else
        message = "[Dawn], day #{day_number}.  The sun will set again in #{default_time_remaining_in_round} seconds."
      end

      changed
      notify_observers(:action => 'advance_time', :message => message)

      if winner?
        end_game
      end
    end


    def round_expired?
      (time_remaining_in_round > 0) ? false : true
    end


    def tick(seconds)
      @time_remaining_in_round -= seconds
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


    def process_night_actions
      # TODO:  define processing order
      @night_actions.each do |action_name, action_lambda|
        action_lambda[]
        @night_actions.delete action_name
      end

      @night_actions.clear
    end


    def winner?
      remaining_teams = living_players.map{|p| p.team}.uniq
      (remaining_teams.size == 1) ? remaining_teams.first : false
    end


    def print_results
      if winner?
        message = "#{winner?.capitalize} won the game!\n"
      else
        message = "No winner, game was ended prematurely"
      end

      changed
      notify_observers(
        :action => 'game_results', 
        :players => players, 
        :message => message)
    end


    def notify_all(message)
      changed
      notify_observers(
        :action => 'tell_all', 
        :message => message)
    end


    def notify_player(player, message)
      changed
      notify_observers(
        :action => 'tell_player', 
        :player => player,
        :message => message)
    end   


  end

end
