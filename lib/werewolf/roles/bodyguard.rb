module Werewolf
  module Roles
    class Bodyguard
      include Roles

      SIDE = :good
      VISIBLE_SIDE = SIDE
      WEIGHT = 3
      POWERS = [:guard]
      ALLIES = []
      DESCRIPTION = "protects one player from the wolves each night."
    end
  end
end
