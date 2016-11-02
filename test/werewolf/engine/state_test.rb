require 'test_helper'

module Werewolf
  class StateTest < Minitest::Test
    def test_state_starts_at_correct_spot
      state = State.new
      assert state.current == :dawn
      assert state.turns == 1
      assert state.day == 1
    end
  end
end
