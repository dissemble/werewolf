module Werewolf
  module Roles
    class Werewolf < Role
      @good = false
      @powers = ["kill"]
      @allies = [Cultist]
    end
  end
end
