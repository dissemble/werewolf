module Werewolf
  module Roles
    class Beholder
      include Roles

      SIDE = :good
      VISIBLE_SIDE = SIDE
      WEIGHT = 2
      POWERS = []
      ALLIES = []
      DESCRIPTION = "knows the identity of the seer."
    end
  end
end
