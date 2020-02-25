require 'test_helper'

module Werewolf

  class GameRolesTest < Minitest::Test

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
      expected = {'bodyguard' => 'guard', 'wolf' => 'kill', 'seer' => 'view'}
      assert_equal expected, Game.roles_with_night_actions
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
      assert_match(/player must be alive/, err.message)
    end


    def test_nightkill_is_not_available_to_nonplayers
      game = Game.new
      game.join Player.new(:name => 'tom', :role => 'villager')
      err = assert_raises(PrivateGameError) {
        game.nightkill werewolf_name:'lupin', victim_name:'tom'
      }
      assert_match(/invalid player name/, err.message)
    end


    def test_nightkill_is_not_available_to_nonwolves
      game = Game.new
      game.join Player.new(:name => 'seth', :role => 'villager')
      game.join Player.new(:name => 'tom', :role => 'villager')
      err = assert_raises(PrivateGameError) {
        game.nightkill werewolf_name:'seth', victim_name:'tom'
      }
      assert_match(/Only wolves may nightkill/, err.message)
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
      assert_match(/player must be alive/, err.message)
    end


    def test_can_only_nightkill_real_players
      game = Game.new
      err = assert_raises(PrivateGameError) {
        game.nightkill werewolf_name:nil, victim_name:'bigfoot'
      }
      assert_match(/invalid player name/, err.message)
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
      assert_match(/no nightkill on night 0/, err.message)
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


    def test_nightkill_calls_slay
      game = Game.new
      villager = Player.new(:name => 'seth', :role => 'villager')
      wolf = Player.new(:name => 'tom', :role => 'wolf')
      [villager, wolf].each {|p| game.join(p)}

      game.stubs(:day_number).returns(1)
      game.expects(:slay).once.with(villager)

      game.nightkill werewolf_name:'tom', victim_name:'seth'
      game.process_night_actions
    end


    def test_nightkill_action_is_acknowledged_immediately
      game = Game.new
      villager = Player.new(:name => 'seth', :role => 'villager')
      wolf = Player.new(:name => 'tom', :role => 'wolf')
      [villager, wolf].each {|p| game.join(p)}

      game.stubs(:day_number).returns(1)
      game.expects(:notify_player).once.with(
        wolf, "kill order acknowledged.  It will take affect at dawn.")

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


    def test_nightkill_adds_a_deferred_action
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


    def test_golem_cannot_be_nightkilled
      game = Game.new
      golem = Player.new(:name => 'john', :role => 'golem')
      wolf = Player.new(:name => 'bill', :role => 'wolf')
      [golem, wolf].each {|p| game.join(p)}

      game.stubs(:day_number).returns(1) # no nightkill on day 0

      game.nightkill werewolf_name:wolf.name, victim_name:golem.name
      game.process_night_actions

      assert golem.alive?
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
      assert_match(/Only the bodyguard can guard/, err.message)
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
      assert_match(/invalid player name/, err.message)
    end


    def test_guard_only_works_at_night
      game = Game.new
      bodyguard = Player.new(:name => 'john', :role => 'bodyguard')
      [bodyguard].each {|p| game.join(p)}

      game.stubs(:time_period).returns('day')

      err = assert_raises(PrivateGameError) do
        game.guard bodyguard_name:bodyguard.name, target_name:bodyguard.name
      end
      assert_match(/Can only guard at night/, err.message)
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
      assert_match(/invalid player name/, err.message)
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
      assert_match(/invalid player name/, err.message)
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
      assert_match(/player must be alive/, err.message)
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


    def test_tanner_victory_initialized_to_false
      game = Game.new
      assert_equal false, game.tanner_victory
      game.reset

    end

    def test_tanner_wins_when_lynched_on_day_1
      game = Game.new
      villager1 = Player.new(:name => 'tom', :role => 'villager')
      villager2 = Player.new(:name => 'john', :role => 'villager')
      tanner = Player.new(:name => 'bill', :role => 'tanner')
      wolf = Player.new(:name => 'seth', :role => 'wolf')
      [villager1, villager2, tanner, wolf].each{|p| game.join(p)}

      game.stubs(:time_period).returns('night')
      game.stubs(:day_number).returns(1)
      game.lynch_player tanner

      assert_equal 'tanner', game.winner?
    end


    def test_tanner_does_not_win_when_lynched_on_day_2
      game = Game.new
      villager1 = Player.new(:name => 'tom', :role => 'villager')
      villager2 = Player.new(:name => 'john', :role => 'villager')
      tanner = Player.new(:name => 'bill', :role => 'tanner')
      wolf = Player.new(:name => 'seth', :role => 'wolf')
      [villager1, villager2, tanner, wolf].each{|p| game.join(p)}

      game.stubs(:time_period).returns('night')
      game.stubs(:day_number).returns(2)
      game.lynch_player tanner

      assert_equal false, game.winner?
    end


    def test_tanner_counts_as_good_for_win_conditions
      game = Game.new
      tanner = Player.new(:name => 'bill', :role => 'tanner')
      game.join(tanner)

      assert_equal 'good', game.winner?
    end


    def test_tanner_counts_as_good_for_win_conditions_2
      game = Game.new
      villager1 = Player.new(:name => 'tom', :role => 'villager')
      tanner = Player.new(:name => 'bill', :role => 'tanner')
      wolf = Player.new(:name => 'seth', :role => 'wolf')
      [villager1, tanner, wolf].each{|p| game.join(p)}

      assert_equal false, game.winner?
    end


    def test_sasquatch_is_initially_good
      player = Player.new(:name => 'tom', :role => 'sasquatch')
      assert_equal 'good', player.team
    end


    def test_sasquatch_role_is_wolf_after_no_lynch
      game = Game.new
      player = Player.new(:name => 'tom', :role => 'sasquatch')
      game.join(player)
      assert_equal 'sasquatch', player.role

      game.no_lynch
      assert_equal 'wolf', player.role
    end


    def test_sasquatch_team_is_evil_after_no_lynch
      game = Game.new
      player = Player.new(:name => 'tom', :role => 'sasquatch')
      game.join(player)
      assert_equal 'good', player.team

      game.no_lynch
      assert_equal 'evil', player.team
    end


    def test_sasquatch_is_notified_when_converted_to_wolf
      game = Game.new
      player = Player.new(:name => 'tom', :role => 'sasquatch')
      game.join player

      game.expects(:notify_player).once().with(
        player, 
        'You have transformed into a wolf.  Go kill some villagers!'
        )

      game.no_lynch
    end


    def test_sasquatch_original_role_is_sasquatch_after_no_lynch
      game = Game.new
      player = Player.new(:name => 'tom', :role => 'sasquatch')
      game.join player
      game.no_lynch
      assert_equal 'sasquatch', player.original_role
      assert_equal 'wolf', player.role
    end


    def test_no_lynch_without_sasquatch
      game = Game.new
      player = Player.new(:name => 'tom', :role => 'villager')
      game.join(player)
      game.no_lynch
    end


    def test_promote_apprentice_called_when_seer_dies_and_apprentice_lives
      game = Game.new
      seer = Player.new(:name => 'tom', :role => 'seer')
      apprentice = Player.new(:name => 'seth', :role => 'apprentice')
      [seer, apprentice].each {|p| game.join p}

      game.expects(:promote_apprentice).once

      game.slay seer
    end


    def test_promote_apprentice_NOT_called_when_nonseer_dies
      game = Game.new
      villager = Player.new(:name => 'tom', :role => 'villager')
      apprentice = Player.new(:name => 'seth', :role => 'apprentice')
      [villager, apprentice].each {|p| game.join p}

      game.expects(:promote_apprentice).never

      game.slay villager
    end


    def test_apprentice_role_is_seer_after_slay
      game = Game.new
      seer = Player.new(:name => 'tom', :role => 'seer')
      apprentice = Player.new(:name => 'seth', :role => 'apprentice')
      [seer, apprentice].each {|p| game.join p}
      game.slay seer
      assert_equal 'seer', apprentice.role
    end


    def test_slay_without_apprentice
      game = Game.new
      villager = Player.new(:name => 'tom', :role => 'villager')
      game.join villager
      game.slay villager
    end


    def test_apprentice_original_role_is_apprentice_after_slay
      game = Game.new
      seer = Player.new(:name => 'tom', :role => 'seer')
      apprentice = Player.new(:name => 'seth', :role => 'apprentice')
      [seer, apprentice].each {|p| game.join p}
      game.slay seer
      assert_equal 'apprentice', apprentice.original_role
    end


    def test_apprentice_is_notified_when_promoted_to_seer
      game = Game.new
      player = Player.new(:name => 'tom', :role => 'apprentice')
      game.join player

      game.expects(:notify_player).once().with(
        player, 'You have been promoted to seer.  Go find some wolves!')

      game.promote_apprentice
    end

  end

end