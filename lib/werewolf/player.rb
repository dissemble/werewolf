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
      end
    end

    # def hash()
    #   name.hash()
    # end

    # def eql?(other)
    #   @name == other.name
    # end
  end
  
end
