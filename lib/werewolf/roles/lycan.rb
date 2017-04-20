module Werewolf
  module Roles
    class Lycan
      include Roles

      TEAM = :villager
      VISIBLE_TEAM = :werewolves
      WEIGHT = -1
      ALLIES = []
      POWERS = {}
      DESCRIPTION = "no special powers."
    end
  end
end
