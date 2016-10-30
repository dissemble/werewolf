require 'test_helper'

module Werewolf
  class SlackbotTest < Minitest::Test

    def test_can_observe_game
      game = Game.new
      slackbot = Werewolf::SlackBot.new
      game.add_observer(slackbot)
    end


    def test_tell_player_with_bot
      slackbot = Werewolf::SlackBot.new
      slackbot.tell_player(Player.new(:name => 'seth', :bot => true), "amessage")
    end


    # TODO:  collapse next 2 tests
    def test_game_notifies_on_advance_time
      game = Game.new
      slackbot = Werewolf::SlackBot.new
      game.add_observer(slackbot)

      slackbot.expects(:update).with(
        :action => 'advance_time',
        :title => "[:sunrise: Dawn], day 1",
        :message => "The sun will set again in #{game.default_time_remaining_in_round} seconds :hourglass:.")

      game.advance_time
    end


    def test_handle_advance_time_called_when_notified
      slackbot = Werewolf::SlackBot.new
      message = "bobby shaftoe's gone to sea"
      slackbot.expects(:handle_advance_time).once.with(:message => "#{message}")

      slackbot.update(
        :action => 'advance_time',
        :message => message)
    end


    def test_advance_time_broadcasts_to_room
      slackbot = Werewolf::SlackBot.new
      message = "i see the moon, and the moon sees me."
      slackbot.expects(:tell_all).once.with(message, {:title => nil})
      slackbot.handle_advance_time(:message => message)
    end


    # TODO:  collapse next 2 tests
    def test_game_notifies_on_join
      game = Game.new
      slackbot = Werewolf::SlackBot.new
      game.add_observer(slackbot)
      player = Player.new(:name => 'seth')

      slackbot.expects(:update).with(
        :action => 'join',
        :message => "has joined the game",
        :player => player)

      game.join(player)
    end


    def test_handle_join_called_when_notified
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth')
      message = "bobby shaftoe's gone to sea"
      slackbot.expects(:handle_join).once.with(:player => player, :message => "#{message}")

      slackbot.update(
        :action => 'join',
        :message => message,
        :player => player)
    end


    def test_handle_join_broadcast_to_room
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth')
      message = "ride a cock-horse to banbury cross"

      slackbot.expects(:tell_all).once.with(":white_check_mark: <@#{player.name}> #{message}", {:color => "good"})

      slackbot.handle_join(
        :message => message,
        :player => player)
    end


    def test_handle_leave_broadcast_to_room
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth')

      slackbot.expects(:tell_all).once.with(":homerhide: <@#{player.name}> has left the game", {:color => "warning"})
      slackbot.handle_leave(:player => player)
    end


    def test_handle_help
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth')

      # TODO:  needs love
      slackbot.expects(:tell_player).once
      slackbot.handle_help(:player => player)
    end


    def test_handle_nightkill_broadcasts_to_room
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth', :role => 'musketeer')
      message = "i see the moon, and the moon sees me"
      slackbot.expects(:tell_all).once.with(":skull_and_crossbones: <@seth> (musketeer) #{message}", {:title => "Murder!", :color => "danger"})
      slackbot.handle_nightkill(
        :player => player,
        :message => message)
    end


    def test_handle_reveal_wolves_with_one_wolf
      slackbot = Werewolf::SlackBot.new
      cultist = Player.new(:name => 'tom', :role => 'cultist')
      wolf1 = Player.new(:name => 'seth', :role => 'wolf')

      slackbot.expects(:tell_player).once.with(cultist, ":wolf: The wolf is <@seth>")
      slackbot.handle_reveal_wolves(
        :player => cultist,
        :wolves => [wolf1])
    end


    def test_handle_reveal_wolves_with_multiple
      slackbot = Werewolf::SlackBot.new
      cultist = Player.new(:name => 'tom', :role => 'cultist')
      wolf1 = Player.new(:name => 'bill', :role => 'wolf')
      wolf2 = Player.new(:name => 'seth', :role => 'wolf')
      wolf3 = Player.new(:name => 'john', :role => 'wolf')

      slackbot.expects(:tell_player).once.with(cultist, ":wolf: The wolves are <@bill> and <@seth> and <@john>")
      slackbot.handle_reveal_wolves(
        :player => cultist,
        :wolves => [wolf1, wolf2, wolf3])
    end


    def test_handle_claims
      slackbot = Werewolf::SlackBot.new

      game = Game.new
      bill = Werewolf::Player.new(:name => 'bill')
      tom = Werewolf::Player.new(:name => 'tom')
      seth = Werewolf::Player.new(:name => 'seth', :alive => false)
      [bill, tom, seth].each {|p| game.join(p)}
      game.claim 'bill', 'i am the walrus'
      game.claim 'tom', 'i am the eggman'

      expected = <<MESSAGE
<@bill>:  i am the walrus
<@tom>:  i am the eggman
<@seth>:  -
MESSAGE
      slackbot.expects(:tell_all).once.with(expected, {:title => "Claims :thinking_face:"})

      slackbot.handle_claims(
        :claims => game.claims
        )
    end


    def test_handle_end_game_broadcasts_to_room
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth')
      message = "this justifies the means"
      slackbot.expects(:tell_all).once.with("***** <@seth> #{message}")
      slackbot.handle_end_game(
        :player => player,
        :message => message)
    end


    def test_handle_view_notifies_seer
      slackbot = Werewolf::SlackBot.new
      seer = Player.new(:name => 'seth')
      target = Player.new(:name => 'tom')
      message = "lorem ipsum dolor"

      slackbot.expects(:tell_player).once.with(seer, ":crystal_ball: <@tom> #{message}")

      slackbot.handle_view(
        :action => 'view',
        :seer => seer,
        :target => target,
        :message => message
      )
    end


    def test_handle_behold_notifies_beholder
      slackbot = Werewolf::SlackBot.new
      beholder = Player.new(:name => 'seth')
      seer = Player.new(:name => 'tom')
      message = "da seer be"

      slackbot.expects(:tell_player).once.with(beholder, "#{message} <@tom> :crystal_ball:")

      slackbot.handle_behold(
        :action => 'view',
        :beholder => beholder,
        :seer => seer,
        :message => message
      )
    end


    def test_handle_game_results_broadcasts_to_room
      slackbot = Werewolf::SlackBot.new
      game = Game.new
      game.join(Player.new(:name => 'bill', :role => 'villager', :alive => false))
      game.join(Player.new(:name => 'tom', :role => 'seer', :alive => false))
      game.join(Player.new(:name => 'seth', :role => 'beholder', :alive => false))
      game.join(Player.new(:name => 'john', :role => 'wolf'))

      expected = <<MESSAGE
Evil won the game!
- :ghost: <@bill>: villager
- :ghost: <@tom>: seer
- :ghost: <@seth>: beholder
+ <@john>: wolf
MESSAGE
      slackbot.expects(:tell_all).once.with(expected)

      slackbot.handle_game_results(
        :action => 'game_results',
        :players => game.players,
        :message => "Evil won the game!\n"
      )
    end


    def test_handle_start_broadcasts_to_room
      slackbot = Werewolf::SlackBot.new
      initiator = Player.new(:name => "seth")
      slackbot.expects(:tell_all).once.with(
        "Active roles: [beholder, bodyguard, cultist, seer, villager, wolf]", {
          :title => "<@#{initiator.name}> has started the game. :partyparrot:",
          :color => "good",
          :fields => [
            {
              :title => ":eyes: beholder",
              :value => "team good. knows the identity of the seer.",
              :short => true
            },
            {
              :title => ":shield: bodyguard",
              :value => "team good.  protects one player from the wolves each night.",
              :short => true
            },
            {
              :title => ":dagger_knife: cultist",
              :value => "team evil. knows the identity of the wolves.",
              :short => true
            },
            {
              :title => ":crystal_ball: seer",
              :value => "team good.  views the alignment of one player each night.",
              :short => true
            },
            {
              :title => ":bust_in_silhouette: villager",
              :value => "team good.  no special powers.",
              :short => true
            },
            {
              :title => ":wolf: wolf",
              :value => "team evil.  kills people at night.",
              :short => true
            }
          ]
        },
      )
      slackbot.handle_start(
        :start_initiator => initiator,
        :active_roles => ['villager', 'cultist', 'beholder', 'seer', 'wolf', 'bodyguard'])
    end


    def test_handle_only_shows_active_roles
      slackbot = Werewolf::SlackBot.new
      initiator = Player.new(:name => "seth")
      slackbot.expects(:tell_all).once.with(
        "Active roles: [beholder, cultist, seer]", {
          :title => "<@#{initiator.name}> has started the game. :partyparrot:",
          :color => "good",
          :fields => [
            {
              :title => ":eyes: beholder",
              :value => "team good. knows the identity of the seer.",
              :short => true
            },
            {
              :title => ":dagger_knife: cultist",
              :value => "team evil. knows the identity of the wolves.",
              :short => true
            },
            {
              :title => ":crystal_ball: seer",
              :value => "team good.  views the alignment of one player each night.",
              :short => true
            }
          ]
        },
      )
      slackbot.handle_start(
        :start_initiator => initiator,
        :active_roles => ['cultist', 'beholder', 'seer'])
    end


    def test_handle_tell_player
      fake_player = "bert"
      fake_message = "where is ernie?"

      slackbot = Werewolf::SlackBot.new
      slackbot.expects(:tell_player).once.with(fake_player, fake_message)
      slackbot.handle_tell_player(
        :player => fake_player,
        :message => fake_message)
    end


    def test_handle_tell_all
      fake_message = "look into thy glass"

      slackbot = Werewolf::SlackBot.new
      slackbot.expects(:tell_all).once.with(fake_message)
      slackbot.handle_tell_all(:message => fake_message)
    end


    def test_handle_vote_broadcasts_to_room
      slackbot = Werewolf::SlackBot.new
      voter = Player.new(:name => 'foo')
      votee = Player.new(:name => 'baz')
      message = 'baz'
      slackbot.expects(:tell_all).once.with("<@#{voter.name}> #{message} <@#{votee.name}>")
      slackbot.handle_vote(
        :voter => voter,
        :votee => votee,
        :message => message)
    end


    def test_handle_lynch_player
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth', :role => 'musketeer')
      message = 'and with its head, he went galumphing back'

      slackbot.expects(:tell_all).once.with("***** #{message} <@#{player.name}> (musketeer)")

      slackbot.handle_lynch_player(
        :player => player,
        :message => message)
    end


    def test_game_notifies_on_join_error
      game = Game.new
      slackbot = Werewolf::SlackBot.new
      game.add_observer(slackbot)

      game.stubs(:active?).returns(true)
      player = Player.new(:name => 'seth')
      slackbot.expects(:handle_join_error).once.with(
        :player => player,
        :message =>'game is active, joining is not allowed')

      game.join(player)
    end


    def test_handle_tally
      slackbot = Werewolf::SlackBot.new
      expected =
        "Lynch <@tom>:  (2 votes) - <@seth>, <@bill>\n" \
        "Lynch <@bill>:  (1 vote) - <@tom>"

      slackbot.expects(:tell_all).once.with(expected)

      slackbot.handle_tally( {
        :vote_tally => {
          'tom' => Set.new(['seth', 'bill']),
          'bill' => Set.new(['tom'])
        }
      } )
    end


    def test_handle_tally_when_empty
      slackbot = Werewolf::SlackBot.new
      expected = "No votes yet :zero:"

      slackbot.expects(:tell_all).once.with(expected)

      slackbot.handle_tally({ :vote_tally => {} })
    end


    def test_handler_join_error_broadcasts_to_room
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth')
      message = "humpty dumpty sat on a wall"
      slackbot.expects(:tell_all).once.with(":no_entry: <@#{player.name}> #{message}", {:color => "danger"})
      slackbot.handle_join_error(:player => player, :message => message)
    end


    def test_game_notifies_on_status
      game = Game.new
      slackbot = Werewolf::SlackBot.new
      game.add_observer(slackbot)

      game.stubs(:players).returns({:foo => 123})
      slackbot.expects(:handle_status).once.with(
        :message => ":no_entry: No game running",
        :players => [123])

      game.status
    end


    def test_handler_status_broadcasts_to_room
      slackbot = Werewolf::SlackBot.new
      message = "humpty dumpty sat on a wall"
      fake_players = "no peeps"
      slackbot.stubs(:format_players).returns(fake_players)
      slackbot.expects(:tell_all).once.with("#{message}\n#{fake_players}", {:title => 'Game Status :wolf:'})
      slackbot.handle_status(:message => message, :players => nil)
    end


    def test_format_player
      slackbot = Werewolf::SlackBot.new
      players = Set.new([
        Player.new(:name => 'john'),
        Player.new(:name => 'seth', :alive => false),
        Player.new(:name => 'tom'),
        Player.new(:name => 'bill')
        ])

      assert_equal "Survivors: [<@john>, <@tom>, <@bill>]", slackbot.format_players(players)
    end


    def test_format_player_all_dead
      slackbot = Werewolf::SlackBot.new
      players = Set.new([
        Player.new(:name => 'john', :alive => false),
        Player.new(:name => 'seth', :alive => false),
        ])

      assert_equal "Survivors: []", slackbot.format_players(players)
    end


    def test_format_player_all_alive
      slackbot = Werewolf::SlackBot.new
      players = Set.new([
        Player.new(:name => 'john'),
        Player.new(:name => 'seth'),
        ])

      assert_equal "Survivors: [<@john>, <@seth>]", slackbot.format_players(players)
    end


    def test_format_player_when_no_players
      slackbot = Werewolf::SlackBot.new
      assert_equal "Zero players.  Type `wolfbot join` to join the game.", slackbot.format_players(Set.new())
    end


    def test_tell_all
      slackbot = Werewolf::SlackBot.new
      message = 'ab cum de ex in pro sine sub'
      channel = 'a channel'
      slackbot.channel = channel

      # TODO: mocking interface we don't own
      mock_client = mock("mock_client")
      mock_web_client = mock("mock_web_client")
      mock_client.stubs(:web_client).returns(mock_web_client)
      mock_web_client.expects(:chat_postMessage).once.with(
        :channel => channel,
        :as_user => true,
        :attachments => [
          {
            :fallback => message,
            :color => nil,
            :title => nil,
            :text => message,
            :fields => nil,
            :mrkdwn_in => ['text', 'fields']
          }
        ]
      )
      slackbot.stubs(:client).returns(mock_client)

      slackbot.tell_all(message)
    end


    def test_slackify_with_real_player
      slackbot = Werewolf::SlackBot.new
      assert_equal '<@foo>', slackbot.slackify(Player.new(:name => 'foo'))
    end


    def test_slackify_with_bot
      slackbot = Werewolf::SlackBot.new
      assert_equal 'foo', slackbot.slackify(Player.new(:name => 'foo', :bot => true))
    end


    def test_slackify_with_nil
      slackbot = Werewolf::SlackBot.new
      assert_equal '', slackbot.slackify(nil)
    end

  end
end
