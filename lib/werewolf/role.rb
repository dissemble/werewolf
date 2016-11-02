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

      def side(actual=false)
          actual ? self::SIDE : self::VISIBLE_SIDE
      end

      def powers
        self::POWERS
      end

      def allies
        self::ALLIES
      end
    end
  end
end
