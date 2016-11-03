module Werewolf
  module Roles
    class Cultist
      include Roles

      TEAM = :werewolves
      VISIBLE_TEAM = :villagers
      WEIGHT = -6
      ALLIES = [Werewolf]
      POWERS = {}
      DESCRIPTION = "knows the identity of the wolves."
    end
  end
end
