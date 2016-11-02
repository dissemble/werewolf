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
        @index += 1
        @turn_number += 1
        @day_number += @index/STATES.length
        @index = 0 if @index == STATES.length
        @current = @state_enumerator.next
      end

      def to_s
        "[#{self.current.capitalize}], day #{self.day_number}"
      end
    end
  end
end
