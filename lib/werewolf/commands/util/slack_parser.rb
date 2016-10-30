module Werewolf
  module Commands
    module Util
      class SlackParser

        #'<@U0BGR4GF8>' => 'U0BGR4GF8'
        def SlackParser.extract_username(input)
          match = /<@(.*)>/.match(input)
          if match
            match.captures().first
          else
            nil
          end

        end

      end

    end
  end
end
