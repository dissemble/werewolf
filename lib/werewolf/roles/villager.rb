module Werewolf
  module Roles
    class Villager
      include Roles

      TEAM = :villagers
      VISIBLE_TEAM = TEAM
      WEIGHT = 1
      ALLIES = []
      DESCRIPTION = "no special powers."
    end
  end
end
