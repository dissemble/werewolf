module Werewolf
  module Roles
    class Beholder
      include Roles

      TEAM = :villagers
      VISIBLE_TEAM = TEAM
      WEIGHT = 2
      ALLIES = []
      DESCRIPTION = "knows the identity of the seer."
    end
  end
end
