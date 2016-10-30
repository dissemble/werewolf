require 'test_helper'

module Werewolf
  module Commands
    module Util

      class SlackParserTest < Minitest::Test

        def test_extracting_username_with_match
          expected = 'U0BGR4GF8'
          assert_equal expected, SlackParser.extract_username('<@U0BGR4GF8>')
        end

        def test_extracting_username_without_match
          assert_nil SlackParser.extract_username('seth')
        end

      end

    end
  end
end
