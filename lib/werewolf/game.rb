require 'set'

module Werewolf

  class Game
    attr_reader :players
    attr_accessor :active_roles, :day_number, :time_period

    def initialize()
      @active = false
      @players = Set.new
      @active_roles = nil
      @day_number = 0
      @time_period = nil
    end

    def active?
      @active
    end

    def join(player)
      @players.add(player)
    end

    def start()
      @active = true
    end
  end
end
