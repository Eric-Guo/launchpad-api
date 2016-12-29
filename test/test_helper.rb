$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require "simplecov"
SimpleCov.start

require 'faria/launchpad/api'
require 'minitest/autorun'
