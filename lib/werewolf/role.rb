module Werewolf
  class Role
    @@roles = []

    def self.roles
      @@roles
    end

    def self.inherited(subclass)
      @@roles << subclass
    end

    def self.side
      @side ||= "good"
    end

    def self.powers
      @powers ||= []
    end

    def self.allies
      @allies ||= []
    end

    def self.to_s
      "#{self.name} (#{side})"
    end
  end
end
