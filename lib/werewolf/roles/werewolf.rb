module Werewolf
  module Roles
    class Werewolf < Role
      @side = "evil"
      @powers = ["kill"]
      @allies = [Cultist]
    end
  end
end
