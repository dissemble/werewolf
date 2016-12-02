require 'test_helper'

module Werewolf

  class GameFullTest < Minitest::Test

    def test_full_game
      game = Game.new

      bill = Werewolf::Player.new(:name => 'bill', :bot => true)
      tom = Werewolf::Player.new(:name => 'tom', :bot => true)
      seth = Werewolf::Player.new(:name => 'seth', :bot => true)
      john = Werewolf::Player.new(:name => 'john', :bot => true)
      monty = Werewolf::Player.new(:name => 'monty', :bot => true)
      katie = Werewolf::Player.new(:name => 'katie', :bot => true)
      [bill, tom, seth, john, monty, katie].each {|p| game.join(p)}

      # start 5 player game
      game.stubs(:define_roles).returns ['seer', 'wolf', 'beholder', 'villager', 'cultist', 'lycan']
      game.start

      seer = game.players.values.find {|p| 'seer' == p.role}
      wolf = game.players.values.find {|p| 'wolf' == p.role}
      beholder = game.players.values.find {|p| 'beholder' == p.role}
      villager = game.players.values.find {|p| 'villager' == p.role}
      cultist = game.players.values.find {|p| 'cultist' == p.role}
      lycan = game.players.values.find {|p| 'lycan' == p.role}

      # Dawn - game should be able to auto-advance
      assert game.night_finished?
      game.advance_time

      # Day 1
      assert_equal 6, game.remaining_votes.size
      game.vote(voter_name: seer.name, candidate_name: villager.name)
      game.vote(voter_name: wolf.name, candidate_name: villager.name)
      game.vote(voter_name: lycan.name, candidate_name: villager.name)
      game.vote(voter_name: beholder.name, candidate_name: wolf.name)
      game.vote(voter_name: villager.name, candidate_name: seer.name)
      #cultist doesn't vote
      assert_equal 1, game.remaining_votes.size
      assert !game.night_finished?

      game.vote_tally
      game.status

      # Dusk
      game.advance_time
      assert villager.dead?

      # Night 1
      game.view seer_name:seer.name, target_name:wolf.name
      game.nightkill werewolf_name:wolf.name, victim_name:beholder.name

      # Dawn - is able to auto advance b/c all night actions are in
      assert game.night_finished?
      game.advance_time
      assert beholder.dead?

      # Day 2
      assert_equal 4, game.remaining_votes.size
      game.vote(voter_name: seer.name, candidate_name: cultist.name)
      game.vote(voter_name: wolf.name, candidate_name: cultist.name)
      game.vote(voter_name: lycan.name, candidate_name: cultist.name)
      game.vote(voter_name: cultist.name, candidate_name: seer.name)
      assert_equal 0, game.remaining_votes.size
      assert_equal 2, game.vote_tally.size
      game.status

      # Dusk
      assert game.voting_finished?
      game.advance_time

      # Night 3
      game.view seer_name:seer.name, target_name:wolf.name
      assert !game.night_finished?
      game.nightkill werewolf_name:wolf.name, victim_name:seer.name

      assert_equal false, game.winner?

      # Dawn
      assert game.night_finished?
      game.advance_time
      assert seer.dead?

      assert_equal 'evil', game.winner?
    end
  end

end