require 'test_helper'

module Werewolf
  module Engine
    class StateTest < Minitest::Test
      def test_starts_at_correct_state
        assert_equal State::STATES.first, State.new.time
      end

      def test_starts_in_twilight_state
        assert State.new.twilight?
      end


      def test_starts_at_correct_turn
        assert_equal 0, State.new.turn_number
      end


      def test_starts_at_correct_day
        assert_equal 0, State.new.day_number
      end

      def test_next_advances_the_time
        state = State.new

        current = state.time

        state.next

        assert state.time != current
      end

      def test_next_cycles_the_time
        state = State.new

        initial = state.time

        State::STATES.length.times { assert state.time != state.next }

        assert_equal initial, state.time
      end


      def test_next_advances_the_counters
        state = State.new

        8.times { state.next }
        assert_equal 2, state.day_number
        assert_equal 8, state.turn_number
      end

      def test_twilights_alternate
        state = State.new

        assert state.twilight?
        state.next
        assert !state.twilight?
        state.next
        assert state.twilight?
        state.next
        assert !state.twilight?
        state.next
      end

      def test_describe_during_transition
        state = State.new

        symbol = :thingy
        state.stubs(:time).returns(symbol)
        state.stubs(:day_number).returns(100)
        state.stubs(:twilight?).returns(true)

        assert_equal "[#{symbol.capitalize}], day 100", state.describe
      end

      def test_describe_outside_transition
        state = State.new

        symbol = :thingy
        state.stubs(:time).returns(symbol)
        state.stubs(:day_number).returns(99)
        state.stubs(:twilight?).returns(false)

        assert_equal "#{symbol.capitalize}time (day 99)", state.describe
      end
    end
  end
end
