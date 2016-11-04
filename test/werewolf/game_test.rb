require 'test_helper'

module Werewolf

  class GameTest < Minitest::Test

    def test_new_game_is_inactive
      assert !Game.new.active?
    end


    def test_new_game_has_no_players
      assert Game.new.players.empty?
    end


    def test_new_game_has_nil_active_roles
      assert Game.new.active_roles.nil?
    end


    def test_new_game_is_on_day_0
      assert_equal 0, Game.new.day_number
    end


    def test_new_game_time_period_is_night
      assert_equal 'night', Game.new.time_period
    end


    def test_join_add_to_players
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'wesley')

      game.join player1
      game.join player2

      expected = {player1.name => player1, player2.name =>player2}
      assert_equal expected, game.players
    end


    def test_same_name_cant_join_twice
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'seth')

      game.join player1
      game.join player2

      expected = {player1.name => player1}
      assert_equal expected, game.players
    end


    def test_leave_leaves_game
      game = Game.new
      player = Player.new(:name => 'seth')

      game.join player
      assert game.players.values.include?(player)

      game.leave player.name
      assert !game.players.values.include?(player)
    end


    def test_must_be_player_to_leave
      game = Game.new
      err = assert_raises(PrivateGameError) do
        game.leave 'tintin'
      end
      assert_match /must be player to leave game/, err.message
    end


    def test_cant_leave_if_game_is_active
      game = Game.new
      player = Player.new(:name => 'seth')
      game.join player
      game.start
      err = assert_raises(PrivateGameError) do
        game.leave player.name
      end
      assert_match /can't leave an active game/, err.message
    end


    def test_leave_notifies_room
      game = Game.new
      player = Player.new(:name => 'seth')
      game.join player

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(:action => 'leave', :player => player)
      game.add_observer mock_observer
      game.expects(:assign_roles).never

      game.leave player.name
    end


    def test_game_can_be_started
      game = Game.new
      game.join Player.new(:name => 'seth')
      game.start
    end


    def test_game_cannot_be_started_twice
      game = Game.new
      game.join Player.new(:name => 'seth')
      game.start

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'tell_all',
        :message => 'Game is already active')
      game.add_observer mock_observer
      game.expects(:assign_roles).never

      game.start
    end


    def test_game_needs_at_least_one_player_to_start
      game = Game.new

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'tell_all',
        :message => "Game can't start until there is at least 1 player")
      game.add_observer mock_observer
      game.expects(:assign_roles).never

      game.start
    end


    def test_once_started_game_is_active
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.start
      assert game.active?
    end


    def test_add_username_to_game()
      game = Game.new
      game.add_username_to_game('seth')
      assert_equal 'seth', game.players.keys.first
    end


    def test_roles_are_assigned_at_game_start
      game = Game.new
      game.join Player.new(:name => 'seth')
      game.expects(:assign_roles).once
      game.stubs(:notify_start)
      game.start
    end


    def test_assign_roles_defines_the_active_roles
      game = Game.new
      game.join Player.new(:name => 'seth')
      fake_roles = [:foo]
      game.expects(:define_roles).once.returns(fake_roles)
      game.assign_roles
      assert_equal fake_roles, game.active_roles
    end



    def test_assign_roles_assigns_one_active_role_to_each_player
      game = Game.new
      roles = [:a, :b, :c, :d]

      game.add_username_to_game 'john'
      game.add_username_to_game 'seth'
      game.add_username_to_game 'tom'
      game.add_username_to_game 'bill'
      game.expects(:define_roles).once.returns(roles)
      game.assign_roles

      game.players.values.each do |player|
        assert roles.find{ |r| r == player.role }
      end

      roles_assigned_to_players = game.players.values.map{|p| p.role}
      roles.each do |role|
        assert roles_assigned_to_players.find{ |r| r == role }
      end
    end


    def test_define_roles_4_player_game
      game = Game.new
      1.upto(4) { |i| game.add_username_to_game("#{i}") }
      expected = ['seer', 'villager', 'villager', 'wolf']
      assert_equal expected, game.define_roles
    end


    def test_define_roles_create_right_number_of_roles
      valid_roles = Set.new ['seer', 'beholder', 'villager', 'cultist', 'wolf', 'bodyguard']

      1.upto(12) do |num_roles|
        game = Game.new
        1.upto(num_roles) { |i| game.add_username_to_game("#{i}") }
        defined_roles = game.define_roles
        assert_equal num_roles, defined_roles.size
        defined_roles.each {|r| valid_roles.include? r}
      end
    end


    # TODO: 13-whatever people
    def test_define_roles_for_large_games

    end


    def test_define_roles_raises_if_no_roleset_for_number_of_players
      game = Game.new

      err = assert_raises(NotImplementedError) {
        game.define_roles
      }
      assert_match /no rolesets/, err.message
    end


    def test_all_players_have_roles_once_game_starts
      game = Game.new
      game.join Player.new(:name => 'seth')
      game.join Player.new(:name => 'tom')
      game.join Player.new(:name => 'bill')
      game.start

      game.players.values.each do |player|
        assert player.role
      end
    end

    def test_instance_method_returns_new_instance
      assert_equal Game, Game.instance.class
    end

    def test_instance_method_returns_same_instance_when_called_twice
      x = Game.instance
      y = Game.instance
      assert_equal x, y
    end


    def test_format_time_when_game_active_and_night
      game = Game.new
      game.stubs(:active?).returns(true)
      game.stubs(:time_period).returns('night')
      game.stubs(:day_number).returns(17)
      game.stubs(:time_remaining_in_round).returns(45)
      expected = ":night_with_stars: It is night (day 17).  The sun will rise again in 45 seconds. :hourglass:"
      assert_equal expected, game.format_time
    end


    def test_format_time_when_game_active_and_day
      game = Game.new
      game.stubs(:active?).returns(true)
      game.stubs(:time_period).returns('day')
      game.stubs(:day_number).returns(42)
      game.stubs(:time_remaining_in_round).returns(31)
      expected = ":sunrise: It is daylight (day 42).  The sun will set again in 31 seconds. :hourglass:"
      assert_equal expected, game.format_time
    end


    def test_format_time_when_game_inactive
      game = Game.new
      game.stubs(:active?).returns(false)
      assert_equal ":no_entry: No game running", game.format_time
    end


    def test_notification_when_status_called
      game = Game.new
      fake_format_time = "the far end of town where the grickle-grass grows"
      fake_players = {1 => 2, 3 => 4}
      game.stubs(:format_time).returns(fake_format_time)
      game.stubs(:players).returns(fake_players)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'status',
        :message => "#{fake_format_time}",
        :players => [2, 4])
      game.add_observer mock_observer

      game.status
    end


    def test_create_time_period_generator
      game = Game.new
      generator = game.create_time_period_generator
      assert_equal ['night', 0],  generator.next
      assert_equal ['day', 1],    generator.next
      assert_equal ['night', 1],  generator.next
      assert_equal ['day', 2],    generator.next
      assert_equal ['night', 2],  generator.next
      assert_equal ['day', 3],    generator.next
    end


    def test_advance_time
      game = Game.new
      game.start

      assert_equal 'night', game.time_period
      assert_equal 0, game.day_number

      game.advance_time
      assert_equal 'day', game.time_period
      assert_equal 1, game.day_number

      game.advance_time
      assert_equal 'night', game.time_period
      assert_equal 1, game.day_number

      game.advance_time
      assert_equal 'day', game.time_period
      assert_equal 2, game.day_number
    end


    def test_advance_time_calls_process_night_actions
      game = Game.new
      game.stubs(:time_period).returns('day')
      game.expects(:process_night_actions).once
      game.advance_time
    end


    def test_advance_time_calls_lynch
      game = Game.new
      game.stubs(:time_period).returns('night')
      game.expects(:lynch).once
      game.advance_time
    end


    def test_advance_time_notifies_of_dawn
      game = Game.new
      game.stubs(:time_period).returns('day')
      game.stubs(:day_number).returns(17)
      game.stubs(:default_time_remaining_in_round).returns(42)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'dawn',
        :day_number => 17,
        :round_time => 42)
      game.add_observer mock_observer

      game.advance_time
    end


    def test_advance_time_notifies_of_dusk
      game = Game.new
      game.stubs(:time_period).returns('night')
      game.stubs(:day_number).returns(17)
      game.stubs(:default_time_remaining_in_round).returns(42)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'dusk',
        :day_number => 17,
        :round_time => 42)
      game.add_observer mock_observer
      game.expects(:lynch)

      game.advance_time
    end


    def test_process_night_actions_applies_all_actions
      game = Game.new
      x = 10
      game.night_actions['nightkill'] = lambda {x *= 2}
      game.night_actions['view'] = lambda {x += 5}

      game.process_night_actions
      assert_equal 25, x
    end


    def test_process_night_actions_leaves_night_actions_empty
      game = Game.new
      x = 10
      game.night_actions['nightkill'] = lambda {x *= 2}
      game.night_actions['view'] = lambda {x += 5}
      assert !game.night_actions.empty?

      game.process_night_actions
      assert game.night_actions.empty?
    end


    def test_process_night_actions_does_not_apply_unknown_actions
      game = Game.new
      x = 10
      game.night_actions['nightkill'] = lambda {x *= 2}
      game.night_actions['runningman'] = lambda {x += 5}

      game.process_night_actions
      assert_equal 20, x
    end


    def test_seers_gets_no_view_if_nightkilled_first
      game = Game.new
      seer = Player.new(:name => 'tom', :role => 'seer')
      wolf = Player.new(:name => 'bill', :role => 'wolf')
      [seer, wolf].each {|p| game.join(p)}

      game.stubs(:day_number).returns(1)
      game.view seer_name:seer.name, target_name:wolf.name
      game.nightkill werewolf_name:wolf.name, victim_name:seer.name

      seer.expects(:view).never
      game.process_night_actions
    end


    def test_print_tally_notifies_room
      game = Game.new
      game.stubs(:time_period).returns('day')

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'tally',
        :vote_tally => game.vote_tally)
      game.add_observer(mock_observer)

      game.print_tally
    end


    def test_print_tally_at_night
      game = Game.new
      game.stubs(:time_period).returns('night')
      game.expects(:notify_all).once.with('Nightime.  No voting in progress.')
      game.print_tally
    end


    def test_print_roles
      game = Game.new
      player = Player.new(:name => 'seth')
      game.join(player)
      game.stubs(:active?).returns(true)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'roles',
        :player => player,
        :active_roles => game.active_roles)
      game.add_observer(mock_observer)

      game.print_roles(player.name)
    end


    def test_print_roles_from_non_player
      game = Game.new

      game.expects(:notify_name).once
      err = assert_raises(PrivateGameError) do
        game.print_roles('fake-player-name')
      end
      assert_match /You are not playing/, err.message
    end


    def test_print_roles_with_inactive_game
      game = Game.new
      player = Player.new(:name => 'seth')
      game.join(player)

      game.expects(:notify_name).once
      err = assert_raises(PrivateGameError) do
        game.print_roles(player.name)
      end
      assert_match /Game is not running/, err.message
    end


    def test_game_notifies_when_player_joins
      game = Game.new
      player = Player.new(:name => 'seth')

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(:action => 'join', :player => player)
      game.add_observer mock_observer

      game.join player
    end


    def test_notification_when_already_joined
      game = Game.new
      player = Player.new(:name => 'seth')
      game.join(player)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'join_error',
        :player => player,
        :message => "you already joined!")
      game.add_observer mock_observer

      game.join(player)
    end


    def test_notification_when_joining_active_game
      game = Game.new
      player = Player.new(:name => 'seth')
      game.expects(:active?).once.returns(true)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'join_error',
        :player => player,
        :message => "game is active, joining is not allowed")
      game.add_observer mock_observer

      game.join(player)
    end


    def test_start_call_notify_start_with_starter
      game = Game.new
      player1 = Player.new(:name => 'seth')
      game.join(player1)

      game.expects(:notify_start).once.with(player1)
      game.start player1.name
    end


    def test_start_call_notify_start_without_starter
      game = Game.new
      game.join Player.new(:name => 'seth')

      game.expects(:notify_start).once
      game.start
    end


    def test_notify_start
      game = Game.new
      player1 = Player.new(:name => 'seth')
      game.join(player1)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'start',
        :start_initiator => player1,
        :active_roles => ['foo', 'bar', 'baz'])
      game.add_observer(mock_observer)

      game.stubs(:active_roles).returns(['foo', 'bar', 'baz'])

      game.notify_start player1
    end


    def test_start_notifies_players
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'tom')
      game.join player1
      game.join player2

      game.expects(:notify_of_role).once.with(player1)
      game.expects(:notify_of_role).once.with(player2)

      game.start
    end


    def test_notify_of_role_for_good
      game = Game.new
      player1 = Player.new(:name => 'seth')

      expected_exhortation = "Go hunt some wolves!"
      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'notify_player_role',
        :player => player1,
        :exhortation => expected_exhortation)
      game.add_observer mock_observer
      player1.stubs(:team).returns('good')

      game.notify_of_role player1
    end


    def test_notify_of_role_for_evil
      game = Game.new
      player1 = Player.new(:name => 'seth')

      expected_exhortation = "Go kill some villagers!"

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'notify_player_role',
        :player => player1,
        :exhortation => expected_exhortation)
      game.add_observer mock_observer
      player1.stubs(:team).returns('evil')

      game.notify_of_role player1
    end


    def test_beholder_is_told_of_seer
      game = Game.new
      beholder = Player.new(:name => 'bill', :role => 'beholder')
      game.expects(:reveal_seer_to).once.with(beholder)
      game.notify_of_role beholder
    end


    def test_beholder_notifies_with_seer
      game = Game.new
      seer = Player.new(:name => 'tom', :role => 'seer')
      beholder = Player.new(:name => 'bill', :role => 'beholder')
      game.join seer
      game.join beholder

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'behold',
        :beholder => beholder,
        :seer => seer,
        :message => "The seer is:")
      game.add_observer mock_observer

      game.reveal_seer_to beholder
    end


    def test_cultist_is_told_of_wolves
      game = Game.new
      cultist = Player.new(:name => 'bill', :role => 'cultist')
      game.expects(:reveal_wolves_to).once.with(cultist)
      game.notify_of_role cultist
    end


    def test_wolf_is_told_of_wolves
      game = Game.new
      player1 = Player.new(:name => 'bill', :role => 'wolf')
      Player.new(:name => 'tom', :role => 'wolf')
      game.expects(:reveal_wolves_to).once.with(player1)
      game.notify_of_role player1
    end


    def test_reveal_wolves_to_notifies_player_of_wolves
      game = Game.new
      cultist = Player.new(:name => 'tom', :role => 'cultist')
      villager = Player.new(:name => 'john', :role => 'villager')
      wolf1 = Player.new(:name => 'bill', :role => 'wolf')
      wolf2 = Player.new(:name => 'seth', :role => 'wolf')
      [cultist, wolf1, villager, wolf2].each{|p| game.join(p)}

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'reveal_wolves',
        :player => cultist,
        :wolves => game.wolf_players
        )
      game.add_observer mock_observer

      game.reveal_wolves_to cultist
    end


    def test_wolf_players
      game = Game.new
      cultist = Player.new(:name => 'tom', :role => 'cultist')
      wolf1 = Player.new(:name => 'bill', :role => 'wolf')
      villager = Player.new(:name => 'john', :role => 'villager')
      wolf2 = Player.new(:name => 'seth', :role => 'wolf')
      [cultist, wolf1, villager, wolf2].each{|p| game.join(p)}

      assert_equal [wolf1, wolf2], game.wolf_players
    end


    def test_end_calls_reset
      game = Game.new
      game.stubs(:active?).returns(true)
      game.expects(:reset).once
      game.stubs(:print_results)
      game.end_game
    end

    def test_end_calls_print_results
      game = Game.new
      game.stubs(:active?).returns(true)
      game.expects(:print_results).once
      game.end_game
    end


    def test_end_game_notifies_room
      game = Game.new
      player1 = Player.new(:name => 'seth')
      game.join player1
      game.start

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'end_game',
        :player => player1,
        :message => "ended the game")
      game.add_observer mock_observer

      game.stubs(:print_results)

      game.end_game 'seth'
    end


    def test_cant_end_unless_game_active
      game = Game.new
      err = assert_raises(PrivateGameError) {
        game.end_game
      }
      assert_match /Game is not active/, err.message
    end


    def test_reset_resets_players
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.join(Player.new(:name => 'tom'))
      assert_equal 2, game.players.size

      game.reset
      assert_equal 0, game.players.size
    end


    def test_reset_inactivates_game
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.start
      assert game.active?

      game.reset
      assert !game.active?
    end


    def test_reset_resets_active_roles
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.start
      assert !game.active_roles.nil?

      game.reset
      assert game.active_roles.nil?
    end


    def test_reset_resets_time_period_and_day
      game = Game.new
      game.day_number = 99
      game.time_period = 'justpastmidnight'

      game.reset
      assert_equal 0, game.day_number
      assert_equal 'night', game.time_period
    end


    def test_reset_resets_vote_tally
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.vote_tally = ['fakething']
      assert_equal 1, game.vote_tally.size

      game.reset
      assert_equal 0, game.vote_tally.size
    end


    def test_reset_resets_time_remaining_in_round
      game = Game.new
      game.time_remaining_in_round = 99981
      game.reset
      assert_equal game.default_time_remaining_in_round, game.time_remaining_in_round
    end


    def test_notify_of_active_roles
      game = Game.new
      game.stubs(:active_roles).returns(['a', 'b', 'c'])
      game.expects(:notify_all).once.with("active roles:  [a, b, c]")
      game.notify_of_active_roles
    end


    def test_start_calls_status
      game = Game.new
      game.join(Player.new(:name => 'seth'))
      game.join(Player.new(:name => 'tom'))
      game.expects(:status)

      game.start
    end


    def test_vote
      game = Game.new
      game.add_username_to_game 'seth'
      game.start
      game.stubs(:time_period).returns('day')
      game.vote voter_name: 'seth', candidate_name: 'seth'
    end


    def test_can_only_vote_for_real_players
      game = Game.new
      game.add_username_to_game 'seth'
      game.start

      expected_message = 'invalid player name'
      game.stubs(:time_period).returns('day')
      game.expects(:notify_name).once.with('seth', expected_message)
      err = assert_raises(PrivateGameError) {
        game.vote voter_name: 'seth', candidate_name: 'babar'
      }
      assert_match expected_message, err.message
    end


    def test_can_only_vote_for_living_players
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'tom', :alive => false)
      [player1, player2].each {|p| game.join(p)}
      game.start

      expected_message = 'player must be alive'
      game.stubs(:time_period).returns('day')
      game.expects(:notify_name).once.with(player1.name, expected_message)
      err = assert_raises(PrivateGameError) {
        game.vote voter_name: player1.name, candidate_name: player2.name
      }
      assert_match expected_message, err.message
    end


    def test_can_only_vote_during_day
      game = Game.new
      player1 = Player.new(:name => 'seth')
      game.join(player1)

      game.start
      assert_equal 'night', game.time_period

      # game.stubs(:voting_finished?).returns(false)
      game.stubs(:time_remaining_in_round).returns(19)
      game.expects(:notify_all).once.with('You may not vote at night.  Night ends in 19 seconds')
      err = assert_raises(PublicGameError) {
        game.vote voter_name: 'seth', candidate_name: 'seth'
      }
      assert_match /You may not vote at night/, err.message
    end


    def test_only_real_players_can_vote
      game = Game.new
      game.add_username_to_game 'seth'
      game.start
      expected_message = 'invalid player name'
      game.expects(:notify_name).once.with('babar', expected_message)
      err = assert_raises(PrivateGameError) {
        game.vote voter_name: 'babar', candidate_name: 'seth'
      }
      assert_match expected_message, err.message
    end


    def test_can_only_vote_when_game_is_live
      game = Game.new
      player_name = 'seth'
      expected_message = 'Game has not started'
      game.add_username_to_game player_name
      game.expects(:notify_all).once.with(expected_message)
      err = assert_raises(PublicGameError) {
        game.vote voter_name: player_name, candidate_name: 'seth'
      }
      assert_equal expected_message, err.message
    end



    def test_vote_calls_print_tally
      game = Game.new
      game.add_username_to_game 'seth'
      game.start
      game.stubs(:time_period).returns('day')
      game.expects(:print_tally).once
      game.vote voter_name: 'seth', candidate_name: 'seth'
    end


    def test_voting_finished_when_all_votes_are_in
      game = Game.new
      game.add_username_to_game 'seth'
      game.add_username_to_game 'tom'
      game.add_username_to_game 'bill'
      game.start
      game.stubs(:time_period).returns('day')
      game.stubs(:advance_time).returns(false)
      game.vote voter_name: 'seth', candidate_name: 'seth'
      game.vote voter_name: 'tom', candidate_name: 'seth'
      game.vote voter_name: 'bill', candidate_name: 'seth'
      assert game.voting_finished?
    end


    def test_voting_finished_when_votes_are_missing
      game = Game.new
      game.add_username_to_game 'seth'
      game.add_username_to_game 'tom'
      game.add_username_to_game 'bill'
      game.start
      game.stubs(:time_period).returns('day')
      game.vote voter_name: 'seth', candidate_name: 'seth'
      game.vote voter_name: 'tom', candidate_name: 'seth'
      assert !game.voting_finished?
    end


    def test_voting_finished_when_no_votes
      game = Game.new
      game.add_username_to_game 'seth'
      game.add_username_to_game 'tom'
      game.add_username_to_game 'bill'
      game.stubs(:time_period).returns('day')
      assert !game.voting_finished?
    end


    def test_night_finished_when_no_action
      game = Game.new
      game.join Werewolf::Player.new(:name => 'seth', :role => 'seer')
      assert !game.night_finished?
    end


    def test_night_finished_when_all_night_actions_queued
      game = Game.new
      villager = Werewolf::Player.new(:name => 'bill', :role => 'villager')
      seer = Werewolf::Player.new(:name => 'tom', :role => 'seer')
      wolf1 = Werewolf::Player.new(:name => 'seth', :role => 'wolf')
      wolf2 = Werewolf::Player.new(:name => 'john', :role => 'wolf')
      bodyguard = Werewolf::Player.new(:name => 'monty', :role => 'bodyguard')
      [villager, seer, wolf1, wolf2, bodyguard].each {|p| game.join(p)}

      game.stubs(:time_period).returns('night')
      game.stubs(:day_number).returns(1)

      # no actions queued
      assert !game.night_finished?

      game.nightkill werewolf_name:wolf1.name, victim_name:seer.name
      assert !game.night_finished?

      game.view seer_name:seer.name, target_name:wolf2.name
      assert !game.night_finished?

      game.guard bodyguard_name:bodyguard.name, target_name:seer.name
      assert game.night_finished?
    end


    def test_night_finished_with_two_of_one_role
      game = Game.new
      villager = Werewolf::Player.new(:name => 'bill', :role => 'villager')
      wolf1 = Werewolf::Player.new(:name => 'tom', :role => 'wolf')
      wolf2 = Werewolf::Player.new(:name => 'seth', :role => 'wolf')
      [villager, wolf1, wolf2].each {|p| game.join(p)}

      game.stubs(:time_period).returns('night')
      game.stubs(:day_number).returns(1)

      # no actions queued
      assert !game.night_finished?

      # some actions queued
      game.nightkill werewolf_name:wolf1.name, victim_name:villager.name
      assert game.night_finished?
    end


    def test_roles_with_night_actions
      expected = {'bodyguard' => 'guard', 'wolf' => 'nightkill', 'seer' => 'view'}
      assert_equal expected, Game.roles_with_night_actions
    end


    def test_vote_count_with_one_candidate
      game = Game.new
      game.vote_tally = {'a' => Set.new(['a', 'b', 'c', 'd'])}
      assert_equal 4, game.vote_count
    end


    def test_vote_count_with_no_candidates
      game = Game.new
      game.vote_tally = {}
      assert_equal 0, game.vote_count
    end


    def test_vote_count_with_3_candidates
      game = Game.new
      game.vote_tally = {
        'a' => Set.new(['a', 'b', 'c', 'd']),
        'b' => Set.new(['e', 'f', 'g']),
        'c' => Set.new(['h'])
      }
      assert_equal 8, game.vote_count
    end


    def test_all_players
      game = Game.new
      player1 = Player.new(:name => 'a', :alive => false)
      player2 = Player.new(:name => 'b', :alive => true)
      player3 = Player.new(:name => 'c', :alive => false)
      [player1, player2, player3].each {|p| game.join(p)}

      expected = [player1, player2, player3]
      assert_equal expected, game.all_players
    end


    def test_living_players_all_alive
      game = Game.new
      player1 = Player.new(:name => 'a', :alive => true)
      player2 = Player.new(:name => 'b', :alive => true)
      player3 = Player.new(:name => 'c', :alive => true)

      [player1, player2, player3].each {|p| game.join(p)}
      assert_equal [player1, player2, player3], game.living_players
    end


    def test_living_players_all_dead
      game = Game.new
      player1 = Player.new(:name => 'a', :alive => false)
      player2 = Player.new(:name => 'b', :alive => false)
      player3 = Player.new(:name => 'c', :alive => false)

      [player1, player2, player3].each {|p| game.join(p)}
      assert_equal [], game.living_players
    end


    def test_living_players_some_dead_some_alive
      game = Game.new
      player1 = Player.new(:name => 'a', :alive => false)
      player2 = Player.new(:name => 'b', :alive => true)
      player3 = Player.new(:name => 'c', :alive => false)

      [player1, player2, player3].each {|p| game.join(p)}
      assert_equal [player2], game.living_players
    end


    def test_tally_starts_empty
      game = Game.new
      assert_equal Hash.new, game.vote_tally
    end


    def test_tally_after_voting
      game = Game.new
      game.add_username_to_game 'seth'
      game.add_username_to_game 'tom'
      game.add_username_to_game 'bill'
      game.start
      game.stubs(:time_period).returns('day')
      game.vote voter_name: 'seth', candidate_name: 'tom'
      game.vote voter_name: 'tom', candidate_name: 'bill'
      game.vote voter_name: 'bill', candidate_name: 'tom'

      expected = {
        'tom' => Set.new(['seth', 'bill']),
        'bill' => Set.new(['tom'])
      }
      assert_equal expected, game.vote_tally
    end


    def test_can_only_vote_once
      game = Game.new
      game.add_username_to_game 'seth'
      game.add_username_to_game 'tom'

      game.start
      game.stubs(:time_period).returns('day')

      game.vote(voter_name: 'seth', candidate_name: 'seth')
      expected_tally = {'seth' => Set.new(['seth'])}
      assert_equal expected_tally, game.vote_tally

      game.vote(voter_name: 'seth', candidate_name: 'tom')
      expected_tally = {'tom' => Set.new(['seth'])}
      assert_equal expected_tally, game.vote_tally
    end


    def test_may_not_vote_when_dead
      game = Game.new
      game.join(Player.new(:name => 'seth', :alive => false))
      game.join(Player.new(:name => 'tom'))
      game.expects(:assign_roles)
      game.start
      game.stubs(:time_period).returns('day')
      expected_message = 'player must be alive'

      game.expects(:notify_name).once.with('seth', expected_message)
      err = assert_raises(PrivateGameError) do
        game.vote(voter_name: 'seth', candidate_name: 'tom')
      end
      assert_equal expected_message, err.message
    end


    def test_lynch_player_calls_kill_on_player
      game = Game.new
      player = Player.new(:name => 'seth')
      game.join player
      player.expects(:kill!).once
      game.lynch_player player
    end


    def test_lynch_player_makes_them_dead
      game = Game.new
      player = Player.new(:name => 'seth')
      game.join player
      game.lynch_player player
      assert player.dead?
    end


    def test_lynch_player_notifies
      game = Game.new
      player = Player.new(:name => 'seth')
      game.join player

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'lynch_player',
        :player => player,
        :message => 'With pitchforks in hand, the townsfolk killed')
      game.add_observer(mock_observer)

      game.lynch_player player
    end


    def test_lynch_tie_notifies
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'tom', :role => 'wolf')
      [player1, player2].each {|p| game.join(p)}

      game.expects(:assign_roles).once
      game.start
      game.advance_time

      game.vote voter_name: 'seth', candidate_name: 'tom'
      game.vote voter_name: 'tom', candidate_name: 'seth'

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'tell_all',
        :message => "The townsfolk couldn't decide - no one was lynched")
      game.add_observer mock_observer

      game.lynch
    end


    def test_lynch_called_at_dusk
      game = Game.new
      game.advance_time
      assert_equal 'day', game.time_period

      game.expects(:lynch).once

      game.advance_time
    end


    def test_lynch_with_no_votes
      game = Game.new
      game.lynch
    end


    def test_lynch_with_no_votes_notifies
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'tom')
      game.join player1
      game.join player2

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'tell_all',
        :message => "No one voted - no one was lynched")
      game.add_observer(mock_observer)

      game.lynch
    end


    def test_lynch_kills_tally_leader
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'john')
      [player1, player2].each {|p| game.join(p)}
      game.start

      game.stubs(:time_period).returns('day')
      game.vote(voter_name: 'seth', candidate_name: 'seth')
      game.vote(voter_name: 'john', candidate_name: 'seth')
      assert player1.alive?
      game.expects(:lynch_player).once.with(player1)

      game.lynch
    end


    def test_lynch_kills_no_one_if_tally_is_tied
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'john')
      [player1, player2].each {|p| game.join(p)}
      game.start
      game.stubs(:time_period).returns('day')
      game.vote(voter_name: 'seth', candidate_name: 'john')
      game.vote(voter_name: 'john', candidate_name: 'seth')

      game.lynch
      assert player1.alive?
      assert player2.alive?
    end


    def test_tally_is_cleared_after_lynch
      game = Game.new
      game.add_username_to_game('seth')
      game.start
      game.stubs(:time_period).returns('day')

      game.vote(voter_name: 'seth', candidate_name: 'seth')
      assert_equal 1, game.vote_tally.size

      game.lynch
      assert_equal 0, game.vote_tally.size
    end


    def test_notification_on_successful_vote
      game = Game.new
      player1 = Player.new(:name => 'seth')
      player2 = Player.new(:name => 'tom')
      [player1, player2].each {|p| game.join(p)}
      game.start

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'vote',
        :voter => player1,
        :votee => player2,
        :message => 'voted for')
      game.add_observer(mock_observer)

      game.stubs(:time_period).returns('day')
      game.expects(:print_tally).once
      game.vote(voter_name: 'seth', candidate_name: 'tom')
    end


    def test_nightkill_is_available_to_wolves
      game = Game.new
      game.join Player.new(:name => 'seth', :role => 'wolf')
      game.join Player.new(:name => 'tom', :role => 'villager')
      game.stubs(:day_number).returns(1)
      game.nightkill werewolf_name:'seth', victim_name:'tom'
    end


    def test_nightkill_only_works_for_living_wolves
      game = Game.new
      game.join Player.new(:name => 'seth', :role => 'wolf', :alive => false)
      game.join Player.new(:name => 'tom', :role => 'villager')
      game.stubs(:day_number).returns(1)

      err = assert_raises(PrivateGameError) {
        game.nightkill werewolf_name:'seth', victim_name:'tom'
      }
      assert_match /player must be alive/, err.message
    end


    def test_nightkill_is_not_available_to_nonplayers
      game = Game.new
      game.join Player.new(:name => 'tom', :role => 'villager')
      err = assert_raises(PrivateGameError) {
        game.nightkill werewolf_name:'lupin', victim_name:'tom'
      }
      assert_match /invalid player name/, err.message
    end


    def test_nightkill_is_not_available_to_nonwolves
      game = Game.new
      game.join Player.new(:name => 'seth', :role => 'villager')
      game.join Player.new(:name => 'tom', :role => 'villager')
      err = assert_raises(PrivateGameError) {
        game.nightkill werewolf_name:'seth', victim_name:'tom'
      }
      assert_match /Only wolves may nightkill/, err.message
    end


    def test_can_only_nightkill_living_players
      game = Game.new
      player1 = Player.new(:name => 'seth', :role => 'wolf')
      player2 = Player.new(:name => 'bill', :role => 'villager', :alive => false)
      game.join(player1)
      game.join(player2)

      game.stubs(:day_number).returns(1)
      err = assert_raises(PrivateGameError) {
        game.nightkill werewolf_name:'seth', victim_name:'bill'
        game.process_night_actions
      }
      assert_match /player must be alive/, err.message
    end


    def test_can_only_nightkill_real_players
      game = Game.new
      err = assert_raises(PrivateGameError) {
        game.nightkill werewolf_name:nil, victim_name:'bigfoot'
      }
      assert_match /invalid player name/, err.message
    end


    def test_nightkill_only_works_at_night
      game = Game.new
      game.join Player.new(:name => 'seth', :role => 'wolf')
      game.join Player.new(:name => 'tom', :role => 'villager')
      game.expects(:time_period).once.returns('day')

      expected_message = 'nightkill may only be used at night'
      game.expects(:notify_name).once.with('seth', expected_message)
      err = assert_raises(PrivateGameError) {
        game.nightkill werewolf_name:'seth', victim_name:'tom'
      }
      assert_equal expected_message, err.message
    end


    def test_nightkill_does_not_work_on_night_0
      game = Game.new
      game.join Player.new(:name => 'seth', :role => 'wolf')
      game.join Player.new(:name => 'tom', :role => 'villager')

      err = assert_raises(PrivateGameError) {
        game.nightkill werewolf_name:'seth', victim_name:'tom'
      }
      assert_match /no nightkill on night 0/, err.message
    end


    def test_only_one_nightkill_per_night
      game = Game.new
      game.join Player.new(:name => 'seth', :role => 'wolf')
      game.join Player.new(:name => 'tom', :role => 'villager')
      game.join Player.new(:name => 'bill', :role => 'villager')

      game.stubs(:day_number).returns(1)
      game.nightkill werewolf_name:'seth', victim_name: 'tom'
      game.nightkill werewolf_name: 'seth', victim_name:'bill'
      game.process_night_actions

      assert game.players['tom'].alive?
      assert game.players['bill'].dead?
    end


    def test_nightkill_action_is_acknowledged_immediately
      game = Game.new
      villager = Player.new(:name => 'seth', :role => 'villager')
      wolf = Player.new(:name => 'tom', :role => 'wolf')
      game.join(villager)
      game.join(wolf)

      game.stubs(:day_number).returns(1)
      game.expects(:notify_player).once.with(
        wolf, "Nightkill order acknowledged.  It will take affect at dawn.")

      game.nightkill werewolf_name:'tom', victim_name:'seth'
    end


    def test_nightkill_notifies_room_after_process_night_actions
      game = Game.new
      player1 = Player.new(:name => 'seth', :role => 'wolf')
      game.join(player1)

      game.stubs(:day_number).returns(1)
      game.nightkill werewolf_name:'seth', victim_name:'seth'

      mock_observer = mock('observer')
      mock_observer.expects(:update).with(
        :action => 'nightkill',
        :player => player1,
        :message => "was killed during the night")
      game.add_observer(mock_observer)

      game.process_night_actions
    end


    def test_nightfall_adds_a_deferred_action
      game = Game.new
      game.join Player.new(:name => 'seth', :role => 'wolf')
      assert game.night_actions.empty?

      game.stubs(:day_number).returns(1)
      game.nightkill werewolf_name:'seth', victim_name: 'seth'
      assert !game.night_actions.empty?
    end


    def test_guard_prevents_nightkill
      game = Game.new
      bodyguard = Player.new(:name => 'john', :role => 'bodyguard')
      villager = Player.new(:name => 'tom', :role => 'villager')
      wolf = Player.new(:name => 'bill', :role => 'wolf')
      [bodyguard, villager, wolf].each {|p| game.join(p)}

      game.stubs(:day_number).returns(1)

      game.nightkill werewolf_name:wolf.name, victim_name:villager.name
      game.guard bodyguard_name:bodyguard.name, target_name:villager.name
      game.process_night_actions

      assert villager.alive?
    end


    def test_guard_notifies_when_nightkill_is_prevented
      game = Game.new
      bodyguard = Player.new(:name => 'john', :role => 'bodyguard')
      villager = Player.new(:name => 'tom', :role => 'villager')
      wolf = Player.new(:name => 'bill', :role => 'wolf')
      [bodyguard, villager, wolf].each {|p| game.join(p)}

      game.stubs(:day_number).returns(1)

      game.nightkill werewolf_name:wolf.name, victim_name:villager.name
      game.guard bodyguard_name:bodyguard.name, target_name:villager.name
      game.expects(:notify_all).with("No one was killed during the night")
      game.process_night_actions
    end


    def test_only_one_guard_per_night
      game = Game.new
      bodyguard = Player.new(:name => 'john', :role => 'bodyguard')
      villager1 = Player.new(:name => 'tom', :role => 'villager')
      villager2 = Player.new(:name => 'bill', :role => 'villager')
      [bodyguard, villager1, villager2].each {|p| game.join(p)}

      game.stubs(:day_number).returns(1)
      game.guard bodyguard_name:bodyguard.name, target_name:villager1.name
      assert_equal 1, game.night_actions.size
    end


    def test_guarded_is_cleared_after_process_night_actions
      game = Game.new
      bodyguard = Player.new(:name => 'john', :role => 'bodyguard')
      villager1 = Player.new(:name => 'tom', :role => 'villager')
      [bodyguard, villager1].each {|p| game.join(p)}

      game.guard bodyguard_name:bodyguard.name, target_name:villager1.name
      game.process_night_actions
      assert_nil game.guarded
    end


    def test_guarded_is_reset_with_new_game
      game = Game.new
      game.start
      game.guarded = "foo"
      assert_equal "foo", game.guarded
      game.reset
      assert_nil game.guarded
    end


    def test_guard_only_works_for_bodyguard
      game = Game.new
      seer = Player.new(:name => 'john', :role => 'seer')
      villager1 = Player.new(:name => 'tom', :role => 'villager')
      [seer, villager1].each {|p| game.join(p)}

      game.expects(:assign_roles)
      game.start

      err = assert_raises(PrivateGameError) do
        game.guard(bodyguard_name: seer.name, target_name: villager1.name)
      end
      assert_match /Only the bodyguard can guard/, err.message
    end


    def test_bodyguard_must_be_alive_to_guard
      game = Game.new
      bodyguard = Player.new(:name => 'fred', :role => 'bodyguard', :alive => false)
      [bodyguard].each {|p| game.join(p)}

      expected_message = 'player must be alive'
      game.expects(:notify_name).once.with(bodyguard.name, expected_message)
      err = assert_raises(PrivateGameError) do
        game.guard bodyguard_name:bodyguard.name, target_name:bodyguard.name
      end
      assert_equal expected_message, err.message
    end


    def test_guard_only_works_on_a_real_player
      game = Game.new
      bodyguard = Player.new(:name => 'john', :role => 'bodyguard')
      [bodyguard].each {|p| game.join(p)}

      err = assert_raises(PrivateGameError) do
        game.guard bodyguard_name:bodyguard.name, target_name:'whitneyhouston'
      end
      assert_match /invalid player name/, err.message
    end


    def test_guard_only_works_at_night
      game = Game.new
      bodyguard = Player.new(:name => 'john', :role => 'bodyguard')
      [bodyguard].each {|p| game.join(p)}

      game.stubs(:time_period).returns('day')

      err = assert_raises(PrivateGameError) do
        game.guard bodyguard_name:bodyguard.name, target_name:bodyguard.name
      end
      assert_match /Can only guard at night/, err.message
    end


    def test_guard_is_acknowledged_immediately
      game = Game.new
      bodyguard = Player.new(:name => 'seth', :role => 'bodyguard')
      villager = Player.new(:name => 'tom', :role => 'villager')
      [bodyguard, villager].each {|p| game.join(p)}

      game.expects(:notify_player).with(bodyguard, "Guard order acknowledged.  It will take affect at dawn.")

      game.guard bodyguard_name:bodyguard.name, target_name:villager.name
    end


    def test_night_finished_needs_guard_if_present
      game = Game.new
      bill = Werewolf::Player.new(:name => 'bill', :role => 'bodyguard')
      [bill].each {|p| game.join(p)}

      game.stubs(:time_period).returns('night')
      game.stubs(:day_number).returns(1)

      # no guard action queued
      assert !game.night_finished?

      # add actions queued
      game.guard bodyguard_name:'bill', target_name:'bill'
      assert game.night_finished?
    end


    # TODO
    # night_actions cleared even on error with action



    def test_view
      game = Game.new
      game.join(Player.new(:name => 'seth', :role => 'seer'))
      game.join(Player.new(:name => 'tom', :role => 'villager'))
      game.view seer_name:'seth', target_name:'tom'
    end


    def test_view_only_available_to_players
      game = Game.new
      game.join(Player.new(:name => 'tom', :role => 'villager'))
      err = assert_raises(PrivateGameError) do
        game.view seer_name:'bartelby', target_name:'tom'
      end
      assert_match /invalid player name/, err.message
    end


    def test_view_only_available_to_seer
      game = Game.new
      game.join(Player.new(:name => 'seth', :role => 'villager'))
      game.join(Player.new(:name => 'tom', :role => 'villager'))

      expected_message = 'View is only available to the seer'
      game.expects(:notify_name).once.with('seth', expected_message)
      err = assert_raises(PrivateGameError) do
        game.view seer_name:'seth', target_name:'tom'
      end
      assert_equal expected_message, err.message
    end


    def test_can_only_view_real_players
      game = Game.new
      game.join(Player.new(:name => 'seth', :role => 'seer'))
      err = assert_raises(PrivateGameError) do
        game.view seer_name:'seth', target_name:'hercules'
      end
      assert_match /invalid player name/, err.message
    end


    def test_view_only_available_at_night
      game = Game.new
      game.join(Player.new(:name => 'seth', :role => 'seer'))
      game.stubs(:time_period).returns('day')

      expected_message = 'You can only view at night'
      game.expects(:notify_name).once.with('seth', expected_message)
      err = assert_raises(PrivateGameError) do
        game.view seer_name:'seth', target_name:'seth'
      end
      assert_equal expected_message, err.message
    end


    def test_view_only_available_if_seer_is_alive
      game = Game.new
      game.join(Player.new(:name => 'seth', :role => 'seer', :alive => false))
      err = assert_raises(PrivateGameError) do
        game.view seer_name:'seth', target_name:'seth'
      end
      assert_match /player must be alive/, err.message
    end


    def test_view_adds_a_night_action
      game = Game.new
      game.join(Player.new(:name => 'seth', :role => 'seer'))
      game.join(Player.new(:name => 'tom', :role => 'villager'))
      assert game.night_actions.empty?

      game.view seer_name:'seth', target_name:'tom'
      assert game.night_actions['view']
    end


    def test_view_is_acknowledged_immediately
      game = Game.new
      seer = Player.new(:name => 'seth', :role => 'seer')
      villager = Player.new(:name => 'tom', :role => 'villager')
      game.join(seer)
      game.join(villager)

      game.expects(:notify_player).once.with(
        seer,
        "View order acknowledged.  It will take affect at dawn.")

      game.view seer_name:'seth', target_name:'tom'
    end


    def test_view_notifies_seer
      game = Game.new
      seer = Player.new(:name => 'seth', :role => 'seer')
      villager = Player.new(:name => 'tom', :role => 'villager')
      [seer, villager].each {|p| game.join(p)}

      game.view seer_name:'seth', target_name:'tom'

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'view',
        :seer => seer,
        :target => villager,
        :message => "is on the side of #{villager.team}")
      game.add_observer(mock_observer)

      game.process_night_actions
    end


    def test_seer_gets_n0_view
      game = Game.new
      seer = Player.new(:name => 'seth', :role => 'seer')
      villager = Player.new(:name => 'tom', :role => 'villager')
      wolf = Player.new(:name => 'bill', :role => 'wolf')  # should never be viewed
      [seer, villager, wolf].each { |p| game.join(p) }

      game.stubs(:assign_roles)
      game.expects(:view).once.with(seer_name: seer.name, target_name: villager.name)
      game.start
    end


    def test_n0_will_advance_automatically
      game = Game.new
      seer = Player.new(:name => 'seth', :role => 'seer')
      wolf = Player.new(:name => 'bill', :role => 'wolf')
      bodyguard = Player.new(:name => 'tom', :role => 'bodyguard')
      [seer, wolf, bodyguard].each { |p| game.join(p) }

      game.stubs(:assign_roles)
      game.start
      assert game.night_finished?
    end


    def test_help_notifies_player
      game = Game.new

      mock_observer = mock('observer')
      # TODO:  needs love
      mock_observer.expects(:update).once
      game.add_observer(mock_observer)

      game.help('seth')
    end


    def test_winner
      game = Game.new
      assert game.winner?
    end


    def test_good_wins_when_only_good_players_are_alive
      game = Game.new
      game.join(Player.new(:name => 'villager', :role => 'villager'))
      game.join(Player.new(:name => 'seer', :role => 'seer'))
      game.join(Player.new(:name => 'wolf', :role => 'wolf', :alive => false))
      assert game.winner?
      assert_equal 'good', game.winner?
    end


    def test_evil_wins_when_only_evil_players_are_alive
      game = Game.new
      game.join(Player.new(:name => 'villager', :role => 'villager'))
      game.join(Player.new(:name => 'seer', :role => 'seer'))
      game.join(Player.new(:name => 'wolf', :role => 'wolf'))
      game.players['villager'].kill!
      game.players['seer'].kill!
      assert game.winner?
      assert_equal 'evil', game.winner?
    end


    def test_winner_with_only_evil_alive
      game = Game.new
      game.join(Player.new(:name => 'seth', :role => 'wolf'))
      game.join(Player.new(:name => 'tom', :role => 'villager', :alive => false))
      assert game.winner?
    end


    def test_winner_with_equal_wolves_and_good
      game = Game.new
      game.join(Player.new(:name => 'seth', :role => 'wolf'))
      game.join(Player.new(:name => 'tom', :role => 'villager'))
      assert game.winner?
    end


    def test_winner_with_only_good_and_cultist
      game = Game.new
      game.join(Player.new(:name => 'seth', :role => 'cultist'))
      game.join(Player.new(:name => 'tom', :role => 'villager'))
      assert_equal 'good', game.winner?
    end


    def test_winner_counts_lycan_as_good
      game = Game.new
      game.join(Player.new(:name => 'seth', :role => 'lycan'))
      assert_equal 'good', game.winner?
    end


    def test_print_results
      game = Game.new
      game.join(Player.new(:name => 'bill', :role => 'villager', :alive => false))
      game.join(Player.new(:name => 'tom', :role => 'seer', :alive => false))
      game.join(Player.new(:name => 'john', :role => 'wolf'))

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'game_results',
        :players => game.players,
        :message => "Evil won the game!" )
      game.add_observer(mock_observer)

      game.print_results
    end


    def test_print_results_when_no_winner
      game = Game.new
      game.join(Player.new(:name => 'bill', :role => 'villager'))
      game.join(Player.new(:name => 'tom', :role => 'seer'))
      game.join(Player.new(:name => 'john', :role => 'wolf'))

      assert !game.winner?

      game.print_results
    end



    def test_advance_time_resets_time_remaining_in_round
      game = Game.new
      game.time_remaining_in_round = 4187
      game.advance_time
      assert_equal game.default_time_remaining_in_round, game.time_remaining_in_round
    end


    def test_round_expired_with_positive_time_remaining_in_round
      game = Game.new
      game.time_remaining_in_round = 3
      assert !game.round_expired?
    end


    def test_round_expired_with_negative_time_remaining_in_round
      game = Game.new
      game.time_remaining_in_round = -1
      assert game.round_expired?
    end


    def test_tick
      game = Game.new
      game.time_remaining_in_round = 100
      game.tick(5)
      assert_equal 95, game.time_remaining_in_round
    end


    def test_tick_can_result_in_negative_time_remaining
      game = Game.new
      game.time_remaining_in_round = 5
      game.tick(7)
      expected = -2
      assert_equal expected, game.time_remaining_in_round
    end


    def test_notify_all
      game = Game.new

      message = "hushabye, don't you cry"

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'tell_all',
        :message => message )
      game.add_observer(mock_observer)

      game.notify_all(message)
    end


    def test_notify_player
      game = Game.new

      player = 'charybdis'
      message = "hushabye, don't you cry"

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'tell_player',
        :player => player,
        :message => message)
      game.add_observer(mock_observer)

      game.notify_player(player, message)
    end


    def test_notify_player
      game = Game.new

      player_name = 'charybdis'
      message = "hushabye, don't you cry"

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'tell_name',
        :name => player_name,
        :message => message)
      game.add_observer(mock_observer)

      game.notify_name(player_name, message)
    end


    def test_claims_with_no_players
      game = Game.new

      expected = {}
      assert_equal expected, game.claims
    end


    def test_claims_initial_state
      game = Game.new

      bill = Werewolf::Player.new(:name => 'bill')
      tom = Werewolf::Player.new(:name => 'tom')
      seth = Werewolf::Player.new(:name => 'seth')
      [bill, tom, seth].each {|p| game.join(p)}

      expected = {bill => nil, tom => nil, seth => nil}
      assert_equal expected, game.claims
    end


    def test_claims_when_everyone_has_not_claimed
      game = Game.new
      bill = Werewolf::Player.new(:name => 'bill')
      tom = Werewolf::Player.new(:name => 'tom')
      seth = Werewolf::Player.new(:name => 'seth', :alive => false)
      [bill, tom, seth].each {|p| game.join(p)}

      game.claim 'bill', 'i am the walrus'
      game.claim 'tom', 'i am the eggman'
      # no claim for seth

      expected = {bill => 'i am the walrus', tom => 'i am the eggman', seth => nil}
      assert_equal expected, game.claims
    end


    def test_claim_overwrites_previous_claim
      game = Game.new
      bill = Werewolf::Player.new(:name => 'bill')
      game.join(bill)

      expected = {bill => nil}
      assert_equal expected, game.claims

      game.claim 'bill', 'i am the walrus'
      expected = {bill => 'i am the walrus'}
      assert_equal expected, game.claims

      game.claim 'bill', 'i am the eggman'
      expected = {bill => 'i am the eggman'}
      assert_equal expected, game.claims
    end


    def test_claim_calls_print_claim
      game = Game.new
      bill = Werewolf::Player.new(:name => 'bill')
      game.join(bill)

      game.expects(:print_claims).once

      game.claim 'bill', 'i am the walrus'
    end


    def test_claim_can_only_be_made_by_real_players
      game = Game.new
      err = assert_raises(PrivateGameError) do
        game.claim 'bill', 'i am the walrus'
      end
      assert_match /claim is only available to players/, err.message
    end


    def test_claims_are_reset
      game = Game.new
      bill = Werewolf::Player.new(:name => 'bill')
      game.join(bill)

      game.claim 'bill', 'i am the walrus'
      expected = {bill => 'i am the walrus'}
      assert_equal expected, game.claims

      game.reset
      expected = {}
      assert_equal expected, game.claims
    end


    def test_print_claims
      game = Game.new
      fake_claims = "foo bar baz"
      game.stubs(:claims).returns(fake_claims)

      mock_observer = mock('observer')
      mock_observer.expects(:update).once.with(
        :action => 'claims',
        :claims => fake_claims)
      game.add_observer(mock_observer)

      game.print_claims
    end


    def test_notify_on_error_with_privategameerror
      game = Game.new
      player_name = 'jeremiah'
      error_message = 'not a bullfrog'
      game.expects(:notify_name).once.with(player_name, error_message)
      err = assert_raises(PrivateGameError) do
        game.notify_on_error(player_name) {raise PrivateGameError.new(error_message)}
      end
      assert_equal error_message, err.message
    end


    def test_notify_on_error_with_publicgameerror
      game = Game.new
      player_name = 'jeremiah'
      error_message = 'not a bullfrog'
      game.expects(:notify_all).once.with(error_message)
      err = assert_raises(PublicGameError) do
        game.notify_on_error(player_name) {raise PublicGameError.new(error_message)}
      end
      assert_equal error_message, err.message
    end


    def test_notify_on_error_with_other_error
      game = Game.new
      player_name = 'jeremiah'
      error_message = 'not a bullfrog'
      assert_raises(SecurityError) do
        game.notify_on_error(player_name) {raise SecurityError.new(error_message)}
      end
    end


    def test_aspirations_1
      game = Game.new

      bill = Werewolf::Player.new(:name => 'bill', :bot => true)
      tom = Werewolf::Player.new(:name => 'tom', :bot => true)
      seth = Werewolf::Player.new(:name => 'seth', :bot => true)
      john = Werewolf::Player.new(:name => 'john', :bot => true)
      monty = Werewolf::Player.new(:name => 'monty', :bot => true)
      katie = Werewolf::Player.new(:name => 'katie', :bot => true)
      [bill, tom, seth, john, monty, katie].each {|p| game.join(p)}

      # start 5 player game
      game.stubs(:define_roles).returns ['seer', 'wolf', 'beholder', 'villager', 'cultist', 'lycan']
      game.start

      seer = game.players.values.find {|p| 'seer' == p.role}
      wolf = game.players.values.find {|p| 'wolf' == p.role}
      beholder = game.players.values.find {|p| 'beholder' == p.role}
      villager = game.players.values.find {|p| 'villager' == p.role}
      cultist = game.players.values.find {|p| 'cultist' == p.role}
      lycan = game.players.values.find {|p| 'lycan' == p.role}

      # Dawn - game should be able to auto-advance
      assert game.night_finished?
      game.advance_time

      # Day 1
      game.vote(voter_name: seer.name, candidate_name: villager.name)
      game.vote(voter_name: wolf.name, candidate_name: villager.name)
      game.vote(voter_name: lycan.name, candidate_name: villager.name)
      game.vote(voter_name: beholder.name, candidate_name: wolf.name)
      game.vote(voter_name: villager.name, candidate_name: seer.name)
      #cultist doesn't vote
      assert !game.night_finished?

      game.vote_tally
      game.status

      # Dusk
      game.advance_time
      assert villager.dead?

      # Night 1
      game.view seer_name:seer.name, target_name:wolf.name
      game.nightkill werewolf_name:wolf.name, victim_name:beholder.name

      # Dawn - is able to auto advance b/c all night actions are in
      assert game.night_finished?
      game.advance_time
      assert beholder.dead?

      # Day 2
      game.vote(voter_name: seer.name, candidate_name: cultist.name)
      game.vote(voter_name: wolf.name, candidate_name: cultist.name)
      game.vote(voter_name: lycan.name, candidate_name: cultist.name)
      game.vote(voter_name: cultist.name, candidate_name: seer.name)
      assert_equal 2, game.vote_tally.size
      game.status

      # Dusk
      assert game.voting_finished?
      game.advance_time

      # Night 3
      game.view seer_name:seer.name, target_name:wolf.name
      assert !game.night_finished?
      game.nightkill werewolf_name:wolf.name, victim_name:seer.name

      # Dawn
      assert game.night_finished?
      game.advance_time
      assert seer.dead?
    end

  end

end
