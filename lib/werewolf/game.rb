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

    def active?()
      @active
    end

    def join(player)
      if @players.member? player
        raise ArgumentError, 'already joined'
      else
        @players.add(player)
      end
    end

    def start()
      @active = true
    end

    def format_players()
      if @players.empty?
        "Zero players.  Type 'wolfbot join' to join the game."
      else
        "Players:  " + @players.to_a.map{|p| "<@#{p.name}>" }.join(", ")
      end
    end


    def format_status()
      if !active?
        "No game running.  #{format_players}"
      else
        "Game is active.  #{format_players}"
      end
    end


    def self.instance()
      @instance ||= Game.new
    end
  end
end
