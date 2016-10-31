module Werewolf
  module Roles
    # A role shoud be subclassed and should contain some specific class level instance attributes
    class Role
      # returns bool depending on the side of the role, true for good and false for evil
      attr_reader :good
      # returns an array of type string with commands that a role can use
      attr_reader :powers
      # returns an array of type Role used to sort/message players of a certain role
      attr_reader :allies
    end
  end
end
