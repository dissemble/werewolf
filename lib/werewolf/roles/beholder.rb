module Werewolf
  module Roles
    class Beholder
      include Roles

      TEAM = :villagers
      VISIBLE_TEAM = TEAM
      WEIGHT = 2
      ALLIES = [Seer]
      POWERS = {}
      DESCRIPTION = "knows the identity of the seer."
    end
  end
end
