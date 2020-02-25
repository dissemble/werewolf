require 'test_helper'

module Werewolf
  class EventLoopTest < Minitest::Test

    def test_init_with_game
      game = Game.new
      event_loop = EventLoop.new(game)
      assert_equal game, event_loop.game
    end


    def test_next_with_inactive_game
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(false)

      event_loop.next
    end


    def test_next_with_active_game
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.stubs(:end_game)

      event_loop.next
    end


    def test_next_with_nil_game
      err = assert_raises(RuntimeError) do
        EventLoop.new(nil)
      end
      assert_match(/game must not be nil/, err.message)
    end


    def test_next_calls_advance_time_when_round_expired
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.expects(:round_expired?).returns(true)
      game.expects(:advance_time)
      game.stubs(:end_game)

      event_loop.next
    end


    def test_next_does_NOT_care_if_voting_is_complete_at_night
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.expects(:round_expired?).once.returns(false)
      game.expects(:day?).once.returns(false)
      game.expects(:night?).once.returns(true)
      game.expects(:voting_finished?).never
      game.expects(:night_finished?).once.returns(false)
      game.expects(:advance_time).never
      game.stubs(:end_game)

      event_loop.next
    end


    def test_next_does_NOT_care_if_night_is_complete_during_day
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.expects(:round_expired?).once.returns(false)
      game.expects(:day?).once.returns(true)
      game.expects(:night?).once.returns(false)
      game.expects(:voting_finished?).once.returns(false)
      game.expects(:night_finished?).never
      game.expects(:advance_time).never
      game.stubs(:end_game)

      event_loop.next
    end


    def test_next_calls_advance_time_when_day_round_NOT_expired_but_voting_finished
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.expects(:round_expired?).once.returns(false)
      game.expects(:day?).once.returns(true)
      game.expects(:voting_finished?).once.returns(true)
      game.expects(:notify_all).once.with("All votes have been cast; dusk will come early.")
      game.expects(:advance_time).once
      game.stubs(:end_game)

      event_loop.next
    end


    def test_next_calls_advance_time_when_round_NOT_expired_but_night_finished
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.expects(:round_expired?).once.returns(false)
      game.expects(:day?).once.returns(false)
      game.expects(:night?).once.returns(true)
      game.expects(:night_finished?).once.returns(true)
      game.expects(:notify_all).once.with("All night actions are complete; dawn will come early.")
      game.expects(:advance_time).once
      game.stubs(:end_game)

      event_loop.next
    end


    def test_next_calls_tick_if_no_other_conditions_met_during_day
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.expects(:round_expired?).once.returns(false)
      game.expects(:day?).once.returns(true)
      game.expects(:night?).once.returns(false)
      game.expects(:voting_finished?).once.returns(false)
      game.expects(:tick).once.with(event_loop.time_increment)
      game.stubs(:end_game)

      event_loop.next
    end


    def test_next_calls_tick_if_no_other_conditions_met_during_night
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.expects(:round_expired?).once.returns(false)
      game.expects(:day?).once.returns(false)
      game.expects(:night?).once.returns(true)
      game.expects(:night_finished?).once.returns(false)
      game.expects(:tick).once.with(event_loop.time_increment)
      game.stubs(:end_game)

      event_loop.next
    end


    def test_time_increment
      event_loop = EventLoop.new(Game.new)
      assert_equal 1, event_loop.time_increment
    end


    def test_warning_ticket
      event_loop = EventLoop.new(Game.new)
      assert_equal 30, event_loop.warning_tick
    end


    def test_notification_on_warning_tick_during_day
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.expects(:round_expired?).once.returns(false)
      game.expects(:day?).once.returns(true)
      game.expects(:night?).once.returns(false)
      game.expects(:voting_finished?).once.returns(false)
      game.stubs(:time_remaining_in_round).returns(49)
      event_loop.stubs(:warning_tick).returns(49)
      game.expects(:notify_all).once.with(
        "#{game.time_period} ending in #{game.time_remaining_in_round} seconds")
      game.stubs(:end_game)

      event_loop.next
    end


    def test_notification_on_warning_tick_during_night
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.expects(:round_expired?).once.returns(false)
      game.expects(:day?).once.returns(false)
      game.expects(:night?).once.returns(true)
      game.expects(:night_finished?).once.returns(false)
      game.stubs(:time_remaining_in_round).returns(49)
      event_loop.stubs(:warning_tick).returns(49)
      game.expects(:notify_all).once.with(
        "#{game.time_period} ending in #{game.time_remaining_in_round} seconds")
      game.stubs(:end_game)

      event_loop.next
    end


    def test_no_notification_on_non_warning_tick_during_day
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.expects(:round_expired?).once.returns(false)
      game.expects(:day?).once.returns(true)
      game.expects(:night?).once.returns(false)
      game.expects(:voting_finished?).once.returns(false)
      game.stubs(:time_remaining_in_round).returns(49)
      event_loop.stubs(:warning_tick).returns(50)
      game.expects(:notify_all).never
      game.stubs(:end_game)

      event_loop.next
    end


    def test_no_notification_on_non_warning_tick_during_night
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.expects(:round_expired?).once.returns(false)
      game.expects(:day?).once.returns(false)
      game.expects(:night?).once.returns(true)
      game.expects(:night_finished?).once.returns(false)
      game.stubs(:time_remaining_in_round).returns(49)
      event_loop.stubs(:warning_tick).returns(50)
      game.expects(:notify_all).never
      game.stubs(:end_game)

      event_loop.next
    end


    def test_next_ends_game_if_winner
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.stubs(:winner?).returns(true)
      game.expects(:end_game).once

      event_loop.next
    end


    def test_next_does_NOT_end_game_if_NO_winner
      game = Game.new
      event_loop = EventLoop.new(game)

      game.expects(:active?).returns(true)
      game.stubs(:winner?).returns(false)
      game.expects(:end_game).never

      event_loop.next
    end

  end
end
