require 'test_helper'

module Werewolf

  class RoleTest < Minitest::Test
    def test_roles_are_defined
      assert !Werewolf::Roles::all.empty?
    end

    # make sure all roles have attributes to describe them
    def test_roles_have_attributes
      attributes = [:TEAM, :VISIBLE_TEAM, :WEIGHT, :ALLIES, :DESCRIPTION]
      Werewolf::Roles::all.each do |role|
        attributes.each do |attribute|
          assert defined? "role::#{attribute}", "#{role.name} is missing the #{attribute} attribute"
        end
        assert !role::TEAM.nil?
        assert !role::DESCRIPTION.nil?
      end
    end

    # some roles appear as other teams, make sure the team function behaves as expected
    def test_roles_show_expected_teams
      Werewolf::Roles::all.each do |role|
        assert role.team(true) == role::TEAM
        assert role.team == role::VISIBLE_TEAM
      end
    end

    # teams may be added, we want to make sure all defined roles have a team we know about
    def test_roles_have_valid_teams
      teams = [:villagers, :werewolves]
      Werewolf::Roles::all.each do |role|
        assert teams.include?(role.team), "#{role.name} has an invalid team #{role.team}"
      end
    end
  end
end
