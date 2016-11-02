module Werewolf
  module Roles
    class Werewolf
      include Roles

      TEAM = :werewolves
      VISIBLE_TEAM = TEAM
      WEIGHT = -6
      ALLIES = [Cultist]
      DESCRIPTION = "kills people at night."
    end
  end
end
