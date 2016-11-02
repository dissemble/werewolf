require 'test_helper'

module Werewolf

  class RoleTest < Minitest::Test
    def test_roles_are_defined
      assert !Werewolf::Roles::all.empty?
    end

    def test_roles_have_attributes
      Werewolf::Roles::all.each do |role|
        assert defined? role::SIDE
        assert !role::SIDE.nil?
        assert defined? role::VISIBLE_SIDE
        assert defined? role::WEIGHT
        assert defined? role::POWERS
        assert defined? role::ALLIES
        assert defined? role::DESCRIPTION
        assert !role::DESCRIPTION.nil?
      end
    end

    def test_roles_show_expected_sides
      Werewolf::Roles::all.each do |role|
        assert role.side(true) == role::SIDE
        assert role.side == role::VISIBLE_SIDE
      end
    end
  end
end
