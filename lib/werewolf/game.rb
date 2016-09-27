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
      raise 'Only Player objects may join the game' unless player.respond_to?(:name)

      if @players.member? player
        raise "you already joined"
      else
        @players.add(player)
      end
    end

    def start()
      raise "Game is already active" if active?
      raise "Game can't start until there is at least 1 player" if @players.empty?

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
