# frozen_string_literal: true

# Filter out known warnings from dependencies
if defined?(Warning)
  module Warning
    def self.warn(message)
      return if message.include?('statement not reached') || message.include?('assigned but unused variable')

      super
    end
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'dadata'

require 'minitest/autorun'
require 'minitest/reporters'
require 'webmock/minitest'

unless ENV['RM_INFO']
  Minitest::Reporters.use! [
    # Minitest::Reporters::SpecReporter.new,
    Minitest::Reporters::DefaultReporter.new(color: true, skip_passed: true)
  ]
end
# Configure WebMock to allow external connections by default
WebMock.allow_net_connect!

class Minitest::Test
  def setup
    super
    WebMock.disable_net_connect! # Disable external connections for each test
  end

  def teardown
    WebMock.reset!
    super
  end
end
