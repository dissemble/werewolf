module Werewolf
  module Engine
    class State
      attr_reader :time, :turn_number, :day_number, :enumerator

      STATES = [:dawn, :day, :dusk, :night]
      TRANSITIONS = [:dawn, :dusk]

      # We start at turn 0, :dawn on day 0
      def initialize
        @enumerator = STATES.cycle
        @time = @enumerator.next
        @turn_number, @day_number = 0, 0
      end

      # Advance to the next time period
      def next
        # increment the turn every time next is called
        @turn_number += 1
        # only increment the day if a full cycle has happened
        @day_number += 1 if @turn_number % STATES.length == 0
        @time = @enumerator.next
      end

      def twilight?
        TRANSITIONS.include? @time
      end

      # A more verbose description, suitable for messaging
      def describe
        if twilight?
          "[#{time.capitalize}], day #{day_number}"
        else
          "#{time.capitalize}time (day #{day_number})"
        end
      end

      def to_s
        "<State: time=#{time}, turn_number=#{turn_number}, day_number=#{day_number}>"
      end
    end
  end
end
