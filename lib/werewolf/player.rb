module Werewolf

  class Player
    attr_accessor :name, :side

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
