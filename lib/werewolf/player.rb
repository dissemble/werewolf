module Werewolf

  class Player
    attr_accessor :name, :role

    def initialize(args)
      args.each { |k,v| instance_variable_set("@#{k}", v) }
      @alive = true
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
      role == 'wolf' ? 'evil' : 'good'
    end

    def see(other_player)
      raise RuntimeError.new("only seer may see") unless role == 'seer'
      other_player.team
    end
    
  end
  
end
