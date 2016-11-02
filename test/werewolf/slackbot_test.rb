require 'test_helper'

module Werewolf
  class SlackbotTest < Minitest::Test

    def test_role_icons
      expected = {
        beholder: ':eyes:',
        bodyguard: ':shield:',
        cultist: ':dagger_knife:',
        lycan: ':see_no_evil:',
        seer: ':crystal_ball:',
        villager: ':bust_in_silhouette:',
        wolf: ':wolf:'
      }
      assert_equal expected, Werewolf::SlackBot::ROLE_ICONS
    end


    def test_format_role_beholder
      assert_equal ':eyes: beholder', Werewolf::SlackBot.format_role('beholder')
    end


    def test_format_role_bodyguard
      assert_equal ':shield: bodyguard', Werewolf::SlackBot.format_role('bodyguard')
    end


    def test_format_role_cultist
      assert_equal ':dagger_knife: cultist', Werewolf::SlackBot.format_role('cultist')
    end


    def test_format_role_lycan
      assert_equal ':see_no_evil: lycan', Werewolf::SlackBot.format_role('lycan')
    end


    def test_format_role_seer
      assert_equal ':crystal_ball: seer', Werewolf::SlackBot.format_role('seer')
    end


    def test_format_role_villager
      assert_equal ':bust_in_silhouette: villager', Werewolf::SlackBot.format_role('villager')
    end


    def test_format_role_wolf
      assert_equal ':wolf: wolf', Werewolf::SlackBot.format_role('wolf')
    end


    def test_format_role_only_real_roles
      err = assert_raises(InvalidRoleError) {
        Werewolf::SlackBot.format_role('snark')
      }
      assert_equal 'snark is not a valid role', err.message
    end


    def test_can_observe_game
      game = Game.new
      slackbot = Werewolf::SlackBot.new
      game.add_observer(slackbot)
    end


    def test_tell_player_with_bot
      slackbot = Werewolf::SlackBot.new
      slackbot.tell_player(Player.new(:name => 'seth', :bot => true), "amessage")
    end


    def test_can_set_channel
      slackbot = Werewolf::SlackBot.new
      slackbot.channel = "foo"
    end


    def test_handle_dawn
      slackbot = Werewolf::SlackBot.new
      title = "[:sunrise: Dawn], day 4"
      message = "The sun will set again in 47 seconds :hourglass:."
      slackbot.expects(:tell_all).once.with(message, anything)
      slackbot.handle_dawn(
        :action => 'dawn',
        :day_number => 4,
        :round_time => 47)
    end


    def test_handle_dusk
      slackbot = Werewolf::SlackBot.new
      title = "[:night_with_stars: Dusk], day 5"
      message = "The sun will rise again in 57 seconds :hourglass:."
      slackbot.expects(:tell_all).once.with(message, anything)
      slackbot.handle_dusk(
        :action => 'dusk',
        :day_number => 5,
        :round_time => 57)
    end


    # TODO:  collapse next 2 tests
    def test_game_notifies_on_join
      game = Game.new
      slackbot = Werewolf::SlackBot.new
      game.add_observer(slackbot)
      player = Player.new(:name => 'seth')

      slackbot.expects(:update).with(
        :action => 'join',
        :player => player)

      game.join(player)
    end


    def test_handle_join_called_when_notified
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth')
      slackbot.expects(:handle_join).once.with(:player => player)

      slackbot.update(
        :action => 'join',
        :player => player)
    end


    def test_handle_join_broadcast_to_room
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth')

      slackbot.expects(:tell_all).once.with(":white_check_mark: <@#{player.name}> joins the game", {:color => "good"})

      slackbot.handle_join(
        :player => player)
    end


    def test_handle_leave_broadcast_to_room
      slackbot = Werewolf::SlackBot.new
      player = Player.new(:name => 'seth')

      slackbot.expects(:tell_all).once.with(":leaves: <@#{player.name}> leaves the game", {:color => "warning"})
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
      player = Player.new(:name => 'seth', :role => 'wolf')
      message = "i see the moon, and the moon sees me"
      slackbot.expects(:tell_all).once.with(":skull_and_crossbones: <@seth> (:wolf: wolf) #{message}", {:title => "Murder!", :color => "danger"})
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
:tada: Evil won the game!
- <@bill>: :bust_in_silhouette: villager :coffin:
- <@tom>: :crystal_ball: seer :coffin:
- <@seth>: :eyes: beholder :coffin:
+ <@john>: :wolf: wolf
MESSAGE
      slackbot.expects(:tell_all).once.with(expected)

      slackbot.handle_game_results(
        :action => 'game_results',
        :players => game.players,
        :message => "Evil won the game!"
      )
    end


    def test_handle_start_broadcasts_to_room
      slackbot = Werewolf::SlackBot.new
      initiator = Player.new(:name => "seth")
      slackbot.expects(:tell_all).once.with(
        "Active roles: [beholder, bodyguard, cultist, lycan, seer, villager, wolf]", {
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
              :title => ":see_no_evil: lycan",
              :value => "team good, but appears evil to seer.  no special powers.",
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
        :active_roles => ['villager', 'cultist', 'beholder', 'seer', 'wolf', 'bodyguard', 'lycan'])
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


    def test_handle_notify_role
      player = Player.new(:name => 'seth', :role => 'beholder')
      exhortation = 'Do the thing!'
      expected_message = 'Your role is: :eyes: beholder. Do the thing!'
      slackbot = Werewolf::SlackBot.new
      slackbot.expects(:tell_player).once.with(player, expected_message)
      slackbot.handle_notify_role(:player => player, :exhortation => exhortation)
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


    def test_handle_tell_name
      # TODO:
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
      player = Player.new(:name => 'seth', :role => 'seer')
      message = 'and with its head, he went galumphing back'

      slackbot.expects(:tell_all).once.with("***** #{message} <@#{player.name}> (:crystal_ball: seer)")

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
