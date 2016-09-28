$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'werewolf'

require 'minitest/autorun'

# make test output perty
require "minitest/reporters"
Minitest::Reporters.use!

require 'mocha/mini_test'