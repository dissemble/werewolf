module Werewolf
  module Engine
    class State
      attr_reader :current, :turn_number, :day_number

      TRANSITIONS = {:dawn => :day, :day => :dusk, :dusk => :night, :night => :dawn}

      # We start at turn 1, :dawn on day 1
      def initialize
        @current = :dawn
        @turn_number, @day_number = 1, 1
      end

      # Advance to the next time period
      def next
        @turn_number += 1
        @day_number += @turn_number/TRANSITIONS.length
        @current = TRANSITIONS[@current]
      end

      def to_s
        "[#{self.current.upcase}] on day #{self.day_number}"
      end
    end
  end
end
