module Werewolf
  module Roles
    class << self
      attr_reader :all
    end

    def self.included(base)
      base.extend(ClassMethods)
      @all ||= []
      @all << base
    end

    module ClassMethods
      def description
        self::DESCRIPTION
      end

      def team(actual = false)
          actual ? self::TEAM : self::VISIBLE_TEAM
      end

      def weight
        self::WEIGHT
      end

      def powers
        self::POWERS
      end

      def allies
        self::ALLIES
      end

      def good?(actual = false)
        [:villagers].include? team actual
      end

      def evil?(actual = false)
        [:werewolves].include? team actual
      end

      def describe_team
        s = "on the side of #{team(:actual => true)}"
        if team != team(:actual => true)
          s += ", appears on the side of the #{team} when viewed."
        else
          s += "."
        end
        s
      end

      def <=> (other)
        return weight <=> other.weight
      end

      def to_s
        "#{name.split('::').last}"
      end
    end
  end
end
