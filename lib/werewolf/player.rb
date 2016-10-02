module Werewolf

  class Player
    attr_accessor :name, :role

    def initialize(args)
      args.each { |k,v| instance_variable_set("@#{k}", v) }
    end

    def hash()
      name.hash()
    end

    def eql?(other)
      @name == other.name
    end
  end
  
end
