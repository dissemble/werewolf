module Werewolf
  module Engine
    class State
      attr_reader :current, :turn_number, :day_number

      STATES = [:dawn, :day, :dusk, :night]

      # We start at turn 0, :dawn on day 0
      def initialize
        @state_enumerator = STATES.cycle
        @current = @state_enumerator.next
        @index, @turn_number, @day_number = 0, 0, 0
      end

      # Advance to the next time period
      def next
        # increment the index and turn every time next is called
        @index += 1
        @turn_number += 1
        # only increment the day if a full cycle has happened
        @day_number += @index/STATES.length
        # reset index once we have hit then end of a cycle
        @index = 0 if @index >= STATES.length
        @current = @state_enumerator.next
      end

      def to_s
        "[#{self.current.capitalize}], day #{self.day_number}"
      end
    end
  end
end
