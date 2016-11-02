require 'test_helper'

module Werewolf
  module Engine
    class StateTest < Minitest::Test
      def test_starts_at_correct_state
        assert State.new.current == State::STATES.first
      end


      def test_starts_at_correct_turn
        assert State.new.turn_number == 0
      end


      def test_starts_at_correct_day
        assert State.new.day_number == 0
      end

      def test_next_advances_the_state
        state = State.new

        assert state.current == :dawn
        assert state.next == :day
        assert state.current == :day
        assert state.next == :dusk
        assert state.next == :night
        assert state.next == :dawn
        assert state.next == :day
      end


      def test_next_advances_the_counters
        state = State.new
        1.upto(8).each { |_i| state.next }
        assert state.day_number == 2
        assert state.turn_number == 8
      end
    end
  end
end
