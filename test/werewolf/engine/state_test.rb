require 'test_helper'

module Werewolf
  class StateTest < Minitest::Test
    def test_state_starts_at_correct_spot
      state = State.new
      assert state.current == :dawn
      assert state.turns == 1
      assert state.day == 1
    end

    def test_next_advances_the_state
      state = State.new
      assert state.next == :day
      assert stat.current == :day
      assert state.turn_number == 2
      assert state.day_number == 1
      
      assert state.next == :dusk
      assert state.next == :night
      assert state.next == :dawn
      assert state.day_number == 2
    end
  end
end
