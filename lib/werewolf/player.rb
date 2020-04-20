module Werewolf

  class Player
    attr_reader :bot, :role
    attr_accessor :name, :original_role

    def initialize(args)
      @alive = true
      args.each { |k,v| instance_variable_set("@#{k}", v) }
      @original_role = role
    end

    def alive?
      @alive
    end

    def dead?
      !alive?
    end

    def kill!
      if(dead?)
        raise RuntimeError.new("already dead")
      elsif('lumberjack' == role && @previous_kill_attempt.nil?)
        # Don't kill lumberjack on first kill attempt, give them a mulligan
        @previous_kill_attempt = true
        false
      else
        @alive = false
        true
      end
    end

    def role=(rolename)
      @role = rolename
      @original_role ||= @role
    end

    def team
      ['wolf', 'cultist'].include?(role) ? 'evil' : 'good'
    end

    def apparent_team
      'lycan' == role ? 'evil' : team
    end

    def view(other_player)
      raise RuntimeError.new("only seer may see") unless role == 'seer'
      other_player.apparent_team
    end

    def bot?
      bot
    end

    def to_s
      "#<Player name=#{name}>"
    end

  end

end
