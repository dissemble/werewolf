module Werewolf
  module Roles
    class Cultist
      include Roles

      SIDE = :evil
      VISIBLE_SIDE = :good
      WEIGHT = -6
      ALLIES = []
      DESCRIPTION = "knows the identity of the wolves."
    end
  end
end
