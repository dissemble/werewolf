module Werewolf
  module Roles
    class Bodyguard
      include Roles

      TEAM = :villagers
      VISIBLE_TEAM = TEAM
      WEIGHT = 3
      ALLIES = []
      DESCRIPTION = "protects one player from the wolves each night."
    end
  end
end
