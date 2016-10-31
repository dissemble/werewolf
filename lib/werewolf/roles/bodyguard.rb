module Werewolf
  module Roles
    class Bodyguard < Role
      @side = "good"
      @powers = ["guard"]
      @description = "protects one player from the wolves each night."
    end
  end
end
