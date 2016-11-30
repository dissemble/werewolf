module Werewolf
  class PrivateGameError < StandardError
  end

  class PublicGameError < StandardError
  end

  class InvalidRoleError < StandardError
  end
end
