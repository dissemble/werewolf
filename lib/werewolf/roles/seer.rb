module Werewolf
  module Roles
    class Seer < Role
      @side = "good"
      @powers = ["see"]
      @allies = [Beholder]
      @description = "views the alignment of one player each night."
    end
  end
end
