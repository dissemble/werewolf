module Werewolf
  module Roles
    class Seer
      include Roles

      TEAM = :villagers
      VISIBLE_TEAM = TEAM
      WEIGHT = 7
      ALLIES = [Beholder]
      DESCRIPTION = "sees the alignment of one player each night."
    end
  end
end
