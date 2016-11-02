require 'test_helper'

module Werewolf
  module Engine
    class StateTest < Minitest::Test
      def test_state_starts_at_dawn
        assert State.new.current == :dawn
      end


      def test_state_starts_at_turn_0
        assert State.new.turn_number == 0
      end


      def test_state_starts_at_day_0
        assert State.new.day_number == 0
      end


      def test_next_advances_the_state
        state = State.new

        assert state.next == :day
        assert state.current == :day
        assert state.turn_number == 1
        assert state.day_number == 0

        assert state.next == :dusk
        assert state.turn_number == 2

        assert state.next == :night
        assert state.next == :dawn
        assert state.next == :day
        assert state.day_number == 1
      end
    end
  end
end
