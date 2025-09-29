# frozen_string_literal: true

require 'test_helper'

class TestDadata < Minitest::Test
  def setup
    super
    Dadata.configure do |config|
      config.api_key = 'test_token'
      config.secret_key = 'test_secret'
      config.suggestions_count = 5
      config.timeout_sec = 2
    end
  end

  def test_that_it_has_a_version_number
    refute_nil ::Dadata::VERSION
  end

  def test_configuration
    assert_equal 'test_token', Dadata.api_key
    assert_equal 'test_secret', Dadata.secret_key
    assert_equal 5, Dadata.suggestions_count
    assert_equal 2, Dadata.timeout_sec
  end

  def test_client_initialization
    client = Dadata::Client.new

    assert_instance_of Dadata::Client, client
  end

  def test_client_with_custom_credentials
    client = Dadata::Client.new('custom_token', 'custom_secret')

    assert_instance_of Dadata::Client, client
  end

  def test_configuration_validation_api_key
    Dadata.configure do |config|
      config.api_key = ''
    end
    error = assert_raises(Dadata::ConfigurationError) do
      Dadata.configuration.validate!
    end
    assert_match(/API key can't be blank/, error.message)
  end

  def test_configuration_validation_timeout
    Dadata.configure do |config|
      config.api_key = 'test'
      config.timeout_sec = 0
    end
    error = assert_raises(Dadata::ConfigurationError) do
      Dadata.configuration.validate!
    end
    assert_match(/Timeout must be positive/, error.message)
  end

  def test_configuration_validation_suggestions_count
    Dadata.configure do |config|
      config.api_key = 'test'
      config.suggestions_count = 25
    end

    assert_equal Dadata::MAX_SUGGESTIONS, Dadata.configuration.suggestions_count
  end

  def test_suggestions_count_max_limit
    Dadata.configure do |config|
      config.api_key = 'test'
      config.suggestions_count = 25
    end

    assert_equal Dadata::MAX_SUGGESTIONS, Dadata.configuration.suggestions_count
  end

  def test_secure_logging
    logger_output = StringIO.new
    Dadata.configure do |config|
      config.api_key = 'secret_api_key'
      config.secret_key = 'super_secret'
      config.logger = Logger.new(logger_output)
    end

    # Trigger some logging
    Dadata.configuration.logger.info('API-Key: secret_api_key')
    log_output = logger_output.string

    assert_match(/API-Key: \[FILTERED\]/, log_output)
  end
end
