module Werewolf
  module Roles
    class Seer < Role
      @good = true
      @powers = ["see"]
      @allies = [Beholder]
    end
  end
end
