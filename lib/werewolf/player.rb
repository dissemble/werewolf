module Werewolf

  class Player
    attr_accessor :name, :role

    def initialize(name)
      @name = name
    end

    def hash()
      name.hash()
    end

    def eql?(other)
      @name == other.name
    end
  end
  
end
