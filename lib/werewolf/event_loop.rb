module Werewolf
  class EventLoop
    attr_accessor :game

    def initialize(game)
      raise RuntimeError.new("game must not be nil") unless game
      @game = game
    end

    def time_increment
      1
    end

    def warning_tick
      30
    end

    def next
      if game.active?
        if game.round_expired?
          game.advance_time
        elsif game.day? and game.voting_finished?
          game.notify_all "All votes have been cast; dusk will come early."
          game.advance_time
        elsif game.night? and game.night_finished?
          game.notify_all "All night actions are complete; dawn will come early."
          game.advance_time
        else
          game.tick time_increment

          if (game.time_remaining_in_round == warning_tick)
            game.notify_all("#{game.time_period} ending in #{game.time_remaining_in_round} seconds")
          end
        end

        if game.winner?
          game.end_game
        end
        puts "time remaining in round: #{game.time_remaining_in_round}"
      end
    end

  end
end
