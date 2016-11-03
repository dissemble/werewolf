module Werewolf
  module Roles
    class Werewolf
      include Roles

      TEAM = :werewolves
      VISIBLE_TEAM = TEAM
      WEIGHT = -6
      ALLIES = [Werewolf]
      POWERS = {
        :night => :kill
      }
      DESCRIPTION = "kills people at night."
    end
  end
end
