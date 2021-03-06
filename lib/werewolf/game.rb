require 'set'
require 'observer'

module Werewolf

  class Game
    include Observable

    DEFAULT_ROUND_TIME_IN_SECONDS = 60*70

    cattr_accessor :roles_with_night_actions
    @@roles_with_night_actions = {'bodyguard' => 'guard', 'wolf' => 'kill', 'seer' => 'view'}

    attr_reader :players, :tanner_victory, :round_time
    attr_accessor :active_roles, :day_number, :guarded, :night_actions, :time_period
    attr_accessor :time_remaining_in_round, :vote_tally

    def initialize()
      reset
    end


    def reset
      @players = Hash.new   # {'player_name' => player}
      @active = false
      @active_roles = nil
      @time_period_generator = create_time_period_generator
      @time_period, @day_number = @time_period_generator.next
      @vote_tally = {}      # {'candidate' => Set.new([voter_name_1, vote_name_2])}
      @night_actions = {}   # {'action_name' => lambda}
      @claims = {}
      @guarded = nil
      @tanner_victory = false
      @round_time = DEFAULT_ROUND_TIME_IN_SECONDS
      @time_remaining_in_round = round_time
    end


    def Game.instance()
      @instance ||= Game.new
    end


    def round_time=(duration_in_seconds)
      if active?
        notify_all "Round time can't be changed during a game"
      else
        begin
          duration = Integer(duration_in_seconds)

          if duration < 60
            notify_all "Round time must be more than 60 seconds"
          else
            @round_time = duration
            notify_all "Round time changed to #{@round_time} seconds"
          end
        rescue ArgumentError
          notify_all "Round time must be a whole number"
        end
      end
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
        notify(:action => 'join_error', :player => player, :message => message)
      elsif @players.has_key? player.name
        notify(:action => 'join_error', :player => player, :message => 'you already joined!')
      else
        @players[player.name] = player
        notify(:action => 'join', :player => player)
      end

      status
      player
    end


    def leave(name)
      player = @players[name]
      raise PrivateGameError.new("must be player to leave game") unless player
      raise PrivateGameError.new("can't leave an active game") if active?

      @players.delete name

      notify(:action => 'leave', :player => player)
    end


    def start(starter_name=nil)
      if active?
        notify_all "Game is already active"
      elsif @players.empty?
        notify_all "Game can't start until there is at least 1 player"
      else
        assign_roles
        @active = true

        # clear any claims made pre-game
        @claims = {}

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
          eligible = @players.values.find_all {|p| 'good' == p.apparent_team}
          eligible = eligible - [seer]
          unless eligible.empty?
            view seer_name:seer.name, target_name:eligible.shuffle!.first.name
          end
        end

        # thought: beholder/cultist could be N0 actions for those roles
        # Provide no-op nightkill to fake out 'night_finished?' so N0 auto advances to D1
        @night_actions['kill'] = lambda {}
        @night_actions['guard'] = lambda {}
      end
    end


    def reveal_seer_to(beholder)
      seer = @players.values.find{|p| p.role == 'seer'}
      notify(:action => 'behold', :beholder => beholder, :seer => seer, :message => 'The seer is:')
    end


    def reveal_wolves_to(player)
      notify(:action => 'reveal_wolves', :player => player, :wolves => wolf_players)
    end


    def end_game(name='Unknown')
      raise PrivateGameError.new('Game is not active') unless active?

      ender = @players[name]

      notify(:action => 'end_game', :player => ender, :message => 'ended the game')

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

      notify(
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


    def init_vote!
      @vote_tally = {}
    end


    def voting_finished?
      (living_players.size == vote_count)
    end


    def vote_count
      @vote_tally.values.reduce(0) {|count, s| count + s.size}
    end


    # returns names, not players
    def remaining_votes
      voter_names = Set.new
      @vote_tally.each do |_k,v|
        voter_names += v
      end

      Set.new(living_players.map{|p| p.name}) - voter_names
    end


    def night_finished?
      # find the roles of the living players
      living_roles = Set.new(living_players.map {|p| p.role})

      # filter all possible night_actions to only those which might be performed
      expected_actions = roles_with_night_actions.select {|role,_a| living_roles.include? role}.values

      (expected_actions - night_actions.keys).empty?
    end


    def detect_voting_finished?
      (living_players.size == vote_count)
    end


    def living_players
      @players.values.find_all{|p| p.alive?}
    end


    def dead_players
      @players.values.find_all{|p| p.dead?}
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
          no_lynch
        else
          lynch_player @players[lynchee_name]
        end
      end
    end


    def no_lynch
      notify_all "The townsfolk couldn't decide - no one was lynched"

      sasquatches = living_players.find_all {|p| 'sasquatch' == p.role }
      sasquatches.each do |player|
        player.role = 'wolf'
        notify_player player, 'You have transformed into a wolf.  Go kill some villagers!'
      end
    end


    def lynch_player(player)
      slay player

      if (day_number == 1) && (player.role == 'tanner')
        @tanner_victory = true
      end

      notify(
        :action => 'lynch_player',
        :player => player,
        :message => 'With pitchforks in hand, the townsfolk killed')
    end


    def slay(player)
      dead = player.kill!

      if dead
        if 'seer' == player.role
          promote_apprentice
        end
      else
        # player survived the kill attempt
        notify(
          :action => 'failed_kill',
          :player => player)
      end
    end


    def promote_apprentice
      apprentices = living_players.find_all {|p| 'apprentice' == p.role }
      apprentices.each do |player|
        player.role = 'seer'
        notify_player player, 'You have been promoted to seer.  Go find some wolves!'
      end
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

      @night_actions['kill'] = lambda {
        execute_nightkill victim_player
      }

      # acknowledge nightkill command immediately
      notify_player wolf_player, 'kill order acknowledged.  It will take affect at dawn.'
    end


    def execute_nightkill(victim_player)
      if (victim_player == @guarded) || (victim_player.role == 'golem')
        notify_all "No one was killed during the night"
      else
        slay victim_player
        notify(:action => 'nightkill', :player => victim_player, :message => 'was killed during the night')
      end
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
          notify(
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

      notify(
        :action => 'help',
        :player => player)
    end


    def status()
      message = "#{format_time}"

      notify(:action => 'status', :message => message, :players => players.values)
    end


    def format_time
      if active?
        if time_period == 'night'
          ":night_with_stars: It is night (day #{day_number}).  The sun will rise again in #{time_remaining_in_round} seconds. :hourglass:"
        else
          ":sunrise: It is daylight (day #{day_number}).  The sun will set again in #{time_remaining_in_round} seconds. :hourglass:"
        end
      else
        ":no_entry: No game running.  (next game: #{round_time}s rounds)"
      end
    end



    # classic rolesets
    # 4 => ['seer', 'villager', 'villager', 'wolf'],
    # 5 => ['seer', 'villager', 'villager', 'sasquatch', 'wolf'],
    # 6 => ['seer', 'golem', 'villager', 'villager', 'cultist', 'wolf'],
    # 7 => ['seer', 'beholder', 'villager', 'villager', 'sasquatch', 'wolf', 'wolf'],
    # 8 => ['seer', 'apprentice', 'villager', 'villager', 'villager', 'sasquatch', 'wolf', 'wolf'],
    # 9 => ['seer', 'bodyguard', 'tanner', 'villager', 'villager', 'villager', 'sasquatch', 'wolf', 'wolf'],
    # 10 => ['seer', 'bodyguard', 'beholder', 'tanner', 'villager', 'villager', 'sasquatch', 'cultist', 'wolf', 'wolf'],
    def define_roles
      rolesets = {
        1 => ['tanner'],
        2 => ['seer', 'wolf'],
        3 => ['seer', 'lycan', 'wolf'],
        4 => ['seer', 'bodyguard', 'tanner', 'wolf'],
        5 => ['seer', 'apprentice', 'tanner', 'sasquatch', 'wolf'],
        6 => ['seer', 'lumberjack', 'villager', 'villager', 'cultist', 'wolf'],
        7 => ['seer', 'lumberjack', 'villager', 'villager', 'lycan', 'wolf', 'wolf'],
        8 => ['seer', 'bodyguard', 'lumberjack', 'villager', 'villager', 'tanner', 'wolf', 'wolf'],
        9 => ['seer', 'bodyguard', 'lumberjack', 'villager', 'villager', 'villager', 'cultist', 'cultist', 'wolf'],
        10 => ['seer', 'bodyguard', 'beholder', 'lumberjack', 'villager', 'villager', 'sasquatch', 'cultist', 'wolf', 'wolf'],
        11 => ['seer', 'lumberjack', 'apprentice', 'lycan', 'tanner', 'apprentice', 'villager', 'sasquatch', 'cultist', 'wolf', 'wolf'],
        12 => ['seer', 'bodyguard', 'beholder', 'tanner', 'lumberjack', 'villager', 'villager', 'villager', 'sasquatch', 'cultist', 'wolf', 'wolf'],
        13 => ['seer', 'bodyguard', 'beholder', 'tanner', 'lumberjack', 'villager', 'villager', 'villager', 'lycan', 'sasquatch', 'cultist', 'wolf', 'wolf'],
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


    def night?
      ('night' == time_period)
    end


    def day?
      !night?
    end


    def advance_time
      @time_remaining_in_round = round_time
      @time_period, @day_number = @time_period_generator.next

      if night?
        lynch

        notify(
          :action => 'dusk',
          :day_number => day_number,
          :round_time => round_time)

        prompt_for_night_actions unless winner?
      else
        process_night_actions
        init_vote!

        notify(
          :action => 'dawn',
          :day_number => day_number,
          :round_time => round_time)
      end
    end


    def round_expired?
      (time_remaining_in_round > 0) ? false : true
    end


    def tick(seconds)
      @time_remaining_in_round -= seconds
    end


    def create_time_period_generator
      # TODO:  Enumerator is not thread safe!!!
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
      ['guard', 'kill', 'view'].each do |action_name|
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
      elsif tanner_victory
        'tanner'
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

      # we could do this once a round, not every time.  this is easy though
      dead_players.each {|p| @claims.delete(p)}

      @claims
    end


    def players_with_night_actions
      living_players.select {|player| @@roles_with_night_actions[player.role] }
    end


    def prompt_for_night_actions
      players_with_night_actions.each do |player|
        action = @@roles_with_night_actions[player.role]
        notify_player(player, "Night has fallen.  Reminder:  please use '#{action}' now")
      end
    end


    def print_claims
      notify(:action => 'claims', :claims => claims)
    end


    def print_roles(name)
      player = @players[name]

      notify_on_error(name) do
        raise PrivateGameError.new("You are not playing") unless player
        raise PrivateGameError.new("Game is not running") unless active?
      end

      notify(:action => 'roles', :player => player, :active_roles => active_roles)
    end


    def print_tally
      if 'night' == time_period
        notify_all("Nightime.  No voting in progress.")
      else
        notify(:action => 'tally', :vote_tally => vote_tally, :remaining_votes => remaining_votes)
      end
    end


    def print_results
      if winner?
        message = "#{winner?.capitalize} won the game!"
      else
        message = "No winner, game was ended prematurely"
      end

      notify(
        :action => 'game_results',
        :players => players,
        :message => message)
    end



    def notify_on_error(name, &_block)
      yield
    rescue PrivateGameError => err
      notify_name(name, err.message)
      raise
    rescue PublicGameError => err
      notify_all(err.message)
      raise
    end


    def notify_name(name, message)
      notify(
        :action => 'tell_name',
        :name => name,
        :message => message)
    end


    def notify_all(message)
      notify(
        :action => 'tell_all',
        :message => message)
    end


    def notify_player(player, message)
      notify(
        :action => 'tell_player',
        :player => player,
        :message => message)
    end


    def notify_start(player)
      notify(
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

      notify(:action => 'notify_role', :player => player, :exhortation => exhortation)

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


    def notify(*args)
      changed
      notify_observers(*args)
    end

  end

end
