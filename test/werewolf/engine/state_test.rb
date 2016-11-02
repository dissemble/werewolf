require 'test_helper'

module Werewolf
  module Engine
    class StateTest < Minitest::Test
      def test_starts_at_correct_state
        assert_equal State.new.current, State::STATES.first
      end

      def test_starts_in_transition_state
        assert State.new.transitioning?
      end


      def test_starts_at_correct_turn
        assert_equal State.new.turn_number, 0
      end


      def test_starts_at_correct_day
        assert_equal State.new.day_number, 0
      end

      def test_next_advances_the_state
        state = State.new

        assert_equal state.current, :dawn
        assert_equal state.next, :day
        assert_equal state.current, :day
        assert_equal state.next, :dusk
        assert_equal state.next, :night
        assert_equal state.next, :dawn
        assert_equal state.next, :day
      end


      def test_next_advances_the_counters
        state = State.new

        state.enumerator.expects(:next).times(8)

        8.times { state.next }
        assert_equal state.day_number, 2
        assert_equal state.turn_number, 8
      end

      def test_next_cycles_state
        state = State.new

        state.enumerator.expects(:next).once

        state.next
      end

      def test_transitions_alternate
        state = State.new

        2.times do
          assert state.transitioning?
          state.next
          assert !state.transitioning?
          state.next
        end
      end

      def test_describe_during_transition
        state = State.new

        symbol = :thingy
        state.stubs(:current).returns(symbol)
        state.stubs(:day_number).returns(100)
        state.stubs(:transitioning?).returns(true)

        assert_equal state.describe, "[#{symbol.capitalize}], day 100"
      end

      def test_describe_outside_transition
        state = State.new

        symbol = :thingy
        state.stubs(:current).returns(symbol)
        state.stubs(:day_number).returns(99)
        state.stubs(:transitioning?).returns(false)

        assert_equal state.describe, "#{symbol.capitalize}time (day 99)"
      end
    end
  end
end
