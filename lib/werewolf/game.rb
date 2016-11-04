require 'set'
require 'observer'

module Werewolf

  class Game
    include Observable

    cattr_accessor :roles_with_night_actions
    @@roles_with_night_actions = {'bodyguard' => 'guard', 'wolf' => 'nightkill', 'seer' => 'view'}

    attr_reader :players
    attr_accessor :active_roles, :day_number, :guarded, :night_actions, :time_period
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
      @night_actions = {}   # {'action_name' => lambda}
      @time_remaining_in_round = default_time_remaining_in_round
      @claims = {}
      @guarded = nil
    end


    def default_time_remaining_in_round
      60 * 10
    end


    def self.instance()
      @instance ||= Game.new
    end


    def active?
      @active
    end


    def add_username_to_game(name)
      join Player.new(:name => name)
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
        notify_observers(:action => 'join', :player => player)
      end
    end


    def leave(name)
      player = @players[name]
      raise PrivateGameError.new("must be player to leave game") unless player
      raise PrivateGameError.new("can't leave an active game") if active?

      @players.delete name

      changed
      notify_observers(:action => 'leave', :player => player)
    end


    def start(starter_name=nil)
      if active?
        notify_all "Game is already active"
      elsif @players.empty?
        notify_all "Game can't start until there is at least 1 player"
      else
        assign_roles
        @active = true

        begin
          starting_player = validate_player(starter_name)
        rescue PrivateGameError
          starting_player = Player.new(:name => "GM")
        end

        notify_start starting_player
        status

        @players.values.each do |player|
          notify_of_role player
        end

        # Give seer a random N0 view
        seer = @players.values.find {|p| 'seer' == p.role}
        if(seer)
          non_seers = @players.values - [seer]
          unless non_seers.empty?
            view seer_name:seer.name, target_name:non_seers.shuffle!.first.name
          end
        end

        # thought: beholder/cultist could be N0 actions for those roles
        # Provide no-op nightkill to fake out 'night_finished?' so N0 auto advances to D1
        @night_actions['nightkill'] = lambda {}
        @night_actions['guard'] = lambda {}
      end
    end


    def reveal_seer_to(beholder)
      seer = @players.values.find{|p| p.role == 'seer'}
      changed
      notify_observers(:action => 'behold', :beholder => beholder, :seer => seer, :message => 'The seer is:')
    end


    def reveal_wolves_to(player)
      changed
      notify_observers(:action => 'reveal_wolves', :player => player, :wolves => wolf_players)
    end


    def end_game(name='Unknown')
      raise PrivateGameError.new('Game is not active') unless active?

      ender = @players[name]

      changed
      notify_observers(:action => 'end_game', :player => ender, :message => 'ended the game')

      print_results
      reset
    end


    def add_vote!(voter:, candidate:)
      # add new vote
      if @vote_tally.has_key? candidate.name
        @vote_tally[candidate.name] << voter.name
      else
        @vote_tally[candidate.name] = Set.new([voter.name])
      end
    end


    def remove_vote!(voter:)
      @vote_tally.each do |k,v|
        if v.delete?(voter.name) && v.empty?
          @vote_tally.delete(k)
        end
      end
    end


    def vote(voter_name:, candidate_name:)
      voter, candidate = notify_on_error(voter_name) do
        authorize_vote(voter_name:voter_name, candidate_name:candidate_name)
      end

      remove_vote! voter:voter
      add_vote! voter:voter, candidate:candidate

      changed
      notify_observers(
        :action => 'vote',
        :voter => @players[voter.name],
        :votee => @players[candidate.name],
        :message => "voted for")

      print_tally
    end


    def authorize_vote(voter_name:, candidate_name:)
      voter = validate_player voter_name
      candidate = validate_player candidate_name

      raise PublicGameError.new("Game has not started") unless active?

      unless 'day' == time_period
        message = "You may not vote at night.  Night ends in #{time_remaining_in_round} seconds"
        raise PublicGameError.new(message)
      end

      return voter, candidate
    end


    def voting_finished?
      (living_players.size == vote_count)
    end


    def night_finished?
      # find the roles of the living players
      living_roles = Set.new(living_players.map {|p| p.role})

      # filter all possible night_actions to only those which might be performed
      expected_actions = roles_with_night_actions.select {|r,_a| living_roles.include? r}.values

      (expected_actions - night_actions.keys).empty?
    end


    def detect_voting_finished?
      (living_players.size == vote_count)
    end


    def vote_count
      @vote_tally.values.reduce(0) {|count, s| count + s.size}
    end


    def living_players
      @players.values.find_all{|p| p.alive?}
    end


    def wolf_players
      @players.values.find_all{|p| p.role == 'wolf'}
    end


    def all_players
      @players.values
    end


    def lynch
      if @vote_tally.empty?
        notify_all "No one voted - no one was lynched"
      else
        # this gives the voters for the player with the most votes
        lynchee_name, voters = @vote_tally.max_by{|_k,v| v.size}

        # but there may be a tie.  find anyone with that many voters
        vote_leaders = @vote_tally.select{|_k,v| v.size == voters.size}

        if vote_leaders.size > 1
          # tie
          notify_all "The townsfolk couldn't decide - no one was lynched"
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


    def validate_player(player_name)
      player = @players[player_name]

      raise PrivateGameError.new("invalid player name") unless player
      raise PrivateGameError.new("player must be alive") unless player.alive?

      player
    end


    def nightkill(werewolf_name:, victim_name:)
      wolf_player, victim_player = notify_on_error(werewolf_name) do
        authorize_nightkill(werewolf_name:werewolf_name, victim_name:victim_name)
      end

      @night_actions['nightkill'] = lambda {
        if @guarded == victim_player
          notify_all "No one was killed during the night"
        else
          victim_player.kill!
          changed
          notify_observers(:action => 'nightkill', :player => victim_player, :message => 'was killed during the night')
        end
      }

      # acknowledge nightkill command immediately
      notify_player wolf_player, 'Nightkill order acknowledged.  It will take affect at dawn.'
    end


    def authorize_nightkill(werewolf_name:, victim_name:)
      wolf_player = validate_player werewolf_name
      victim_player = validate_player victim_name

      raise PrivateGameError.new('Only wolves may nightkill') unless 'wolf' == wolf_player.role
      raise PrivateGameError.new('nightkill may only be used at night') unless 'night' == time_period
      raise PrivateGameError.new('no nightkill on night 0') if 0 == day_number

      return wolf_player, victim_player
    end


    def guard(bodyguard_name:, target_name:)
      bodyguard_player, target_player = notify_on_error(bodyguard_name) do
        authorize_guard(bodyguard_name:bodyguard_name, target_name:target_name)
      end

      @night_actions['guard'] = lambda {
        @guarded = target_player
      }

      # acknowledge guard command immediately
      notify_player bodyguard_player, 'Guard order acknowledged.  It will take affect at dawn.'
    end


    def authorize_guard(bodyguard_name:, target_name:)
      bodyguard_player = validate_player bodyguard_name
      target_player = validate_player target_name

      raise PrivateGameError.new("Only the bodyguard can guard") unless 'bodyguard' == bodyguard_player.role
      raise PrivateGameError.new("Can only guard at night") unless time_period == 'night'

      return bodyguard_player, target_player
    end


    def view(seer_name:, target_name:)
      seer, target = notify_on_error(seer_name) do
        authorize_view seer_name:seer_name, target_name:target_name
      end

      @night_actions['view'] = lambda {
        # seer may be nightkilled after calling view, but before his night action is processed
        if seer.alive?
          team = seer.view target
          changed
          notify_observers(
            :action => 'view',
            :seer => seer,
            :target => target,
            :message => "is on the side of #{team}")
        end
      }

      notify_player seer, "View order acknowledged.  It will take affect at dawn."
    end


    def authorize_view(seer_name:, target_name:)
      seer = validate_player seer_name
      target = validate_player target_name

      raise PrivateGameError.new('View is only available to the seer') unless seer.role == 'seer'
      raise PrivateGameError.new('You can only view at night') unless time_period == 'night'

      return seer, target
    end


    def help(name)
      player = Player.new(:name => name)

      changed
      notify_observers(
        :action => 'help',
        :player => player)
    end


    def status()
      message = "#{format_time}"

      changed
      notify_observers(:action => 'status', :message => message, :players => players.values)
    end


    def format_time
      if active?
        if time_period == 'night'
          ":night_with_stars: It is night (day #{day_number}).  The sun will rise again in #{time_remaining_in_round} seconds. :hourglass:"
        else
          ":sunrise: It is daylight (day #{day_number}).  The sun will set again in #{time_remaining_in_round} seconds. :hourglass:"
        end
      else
        ":no_entry: No game running"
      end
    end


    def define_roles
      rolesets = {
        1 => ['seer'],
        2 => ['bodyguard', 'wolf'],
        3 => ['seer', 'bodyguard', 'wolf'],
        4 => ['seer', 'villager', 'villager', 'wolf'],
        5 => ['seer', 'bodyguard', 'villager', 'wolf', 'wolf'],
        6 => ['seer', 'bodyguard', 'lycan', 'villager', 'wolf', 'wolf'],
        7 => ['seer', 'bodyguard', 'lycan', 'villager', 'cultist', 'wolf', 'wolf'],
        8 => ['seer', 'bodyguard', 'beholder', 'lycan', 'villager', 'cultist', 'wolf', 'wolf'],
        9 => ['seer', 'bodyguard', 'beholder', 'lycan', 'villager', 'villager', 'cultist', 'wolf', 'wolf'],
        10 => ['seer', 'bodyguard', 'beholder', 'lycan', 'villager', 'villager', 'villager', 'cultist', 'wolf', 'wolf'],
        11 => ['seer', 'bodyguard', 'beholder', 'lycan', 'villager', 'villager', 'villager', 'villager', 'cultist', 'wolf', 'wolf'],
        12 => ['seer', 'bodyguard', 'beholder', 'lycan', 'villager', 'villager', 'villager', 'villager', 'villager', 'cultist', 'wolf', 'wolf'],
      }

      available_roles = rolesets[@players.size]
      if available_roles.nil?
        raise NotImplementedError.new("no rolesets for #{@players.size} players")
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
        action = 'dusk'
      else
        process_night_actions
        action = 'dawn'
      end

      changed
      notify_observers(
        :action => action,
        :day_number => day_number,
        :round_time => default_time_remaining_in_round)
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
      ['guard', 'nightkill', 'view'].each do |action_name|
        action_lambda = @night_actions[action_name]
        if action_lambda
          action_lambda[]
          @night_actions.delete action_name
        end
      end

      @guarded = nil
      @night_actions.clear
    end


    def winner?
      wolves = @players.values.find_all {|p| (p.alive?) && ('wolf' == p.role)}
      good = @players.values.find_all {|p| (p.alive?) && ('good' == p.team)}

      if wolves.empty?
        'good'
      elsif wolves.size >= good.size
        'evil'
      else
        false
      end
    end


    def claim(name, text)
      player = @players[name]
      raise PrivateGameError.new("claim is only available to players") unless player

      @claims[player] = text
      print_claims
    end


    def claims
      all_players.each {|p| @claims[p] = nil unless @claims[p]}
      @claims
    end


    def print_claims
      changed
      notify_observers(:action => 'claims', :claims => claims)
    end


    def print_tally
      changed
      notify_observers(:action => 'tally', :vote_tally => vote_tally)
    end


    def print_results
      if winner?
        message = "#{winner?.capitalize} won the game!"
      else
        message = "No winner, game was ended prematurely"
      end

      changed
      notify_observers(
        :action => 'game_results',
        :players => players,
        :message => message)
    end



    def notify_on_error(name, &block)
      yield
    rescue PrivateGameError => err
      notify_name(name, err.message)
      raise
    rescue PublicGameError => err
      notify_all(err.message)
      raise
    end


    def notify_name(name, message)
      changed
      notify_observers(
        :action => 'tell_name',
        :name => name,
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


    def notify_start(player)
      changed
      notify_observers(
        :action => 'start',
        :start_initiator => player,
        :active_roles => active_roles)
    end


    def notify_of_role(player)
      if('evil' == player.team)
        exhortation = "Go kill some villagers!"
      elsif('good' == player.team)
        exhortation = "Go hunt some wolves!"
      end

      changed
      notify_observers(:action => 'notify_player_role', :player => player, :exhortation => exhortation)

      if 'beholder' == player.role
        reveal_seer_to player
      elsif 'cultist' == player.role
        reveal_wolves_to player
      elsif 'wolf' == player.role
        reveal_wolves_to player
      end
    end


    def notify_of_active_roles
      role_string = active_roles.join(', ')
      notify_all "active roles:  [#{role_string}]"
    end


  end

end
