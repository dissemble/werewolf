module Werewolf
  module Roles
    class Seer
      include Roles

      SIDE = :good
      VISIBLE_SIDE = SIDE
      WEIGHT = 7
      POWERS = [:see]
      ALLIES = [Beholder]
      DESCRIPTION = "sees the alignment of one player each night."
    end
  end
end
