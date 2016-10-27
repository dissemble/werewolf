module Werewolf

  class Player
    attr_accessor :name, :role

    def initialize(args)
      @alive = true
      args.each { |k,v| instance_variable_set("@#{k}", v) }
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
      else
        @alive = false
        true
      end
    end

    def team
      ['wolf', 'cultist'].include?(role) ? 'evil' : 'good'
    end

    def view(other_player)
      raise RuntimeError.new("only seer may see") unless role == 'seer'
      other_player.team
    end
    
    def bot?
      @bot
    end

    def to_s
      "#<Player name=#{name}>"
    end

  end
  
end
