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

      def team(actual=false)
          actual ? self::TEAM : self::VISIBLE_TEAM
      end

      def powers
        self::POWERS
      end

      def allies
        self::ALLIES
      end

      def good?
        [:villagers].include? team
      end

      def evil?
        [:werewolves].include? team
      end

      def to_s
        "#{name.split('::').last}"
      end
    end
  end
end
