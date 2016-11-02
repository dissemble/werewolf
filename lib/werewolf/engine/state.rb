module Werewolf
  module Engine
    class State
      attr_reader :current, :turn_number, :day_number, :enumerator

      STATES = [:dawn, :day, :dusk, :night]
      TRANSITIONS = [:dawn, :dusk]

      # We start at turn 0, :dawn on day 0
      def initialize
        @enumerator = STATES.cycle
        @current = @enumerator.next
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
        @current = @enumerator.next
      end

      def transitioning?
        TRANSITIONS.include? @current
      end

      # A more verbose description, suitable for messaging
      def describe
        if transitioning?
          "[#{current.capitalize}], day #{day_number}"
        else
          "#{current.capitalize}time (day #{day_number})"
        end
      end

      def to_s
        "<State: current=#{current}, turn_number=#{turn_number}, day_number=#{day_number}>"
      end
    end
  end
end
