module Werewolf
  module Roles
    class Werewolf < Role
      @side = "evil"
      @powers = ["kill"]
      @allies = [Cultist]
      @description = "kills people at night."
    end
  end
end
