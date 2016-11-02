module Werewolf
  module Roles
    class Cultist
      include Roles

      TEAM = :villagers
      VISIBLE_TEAM = :werewolves
      WEIGHT = -6
      ALLIES = []
      DESCRIPTION = "knows the identity of the wolves."
    end
  end
end
