# frozen_string_literal: true

require_relative '../../test_helper'

module Dadata
  class ClientBaseTest < Minitest::Test
    def setup
      super
      @base_url = 'https://api.dadata.ru'
      @token = 'test_token'
      @secret = 'test_secret'
      @client = ClientBase.new(@base_url, @token, @secret)
    end

    def test_successful_get_request
      response_body = { 'result' => 'success' }
      stub_request(:get, "#{@base_url}/test")
        .with(
          headers: {
            'Accept'        => 'application/json',
            'Authorization' => "Token #{@token}",
            'Content-Type'  => 'application/json',
            'X-Secret'      => @secret
          },
          query:   { param: 'value' }
        )
        .to_return(
          status:  200,
          body:    response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = @client.submit('/test', { param: 'value' }, :get)

      assert_equal response_body, result
    end

    def test_successful_post_request
      request_body = { data: 'test' }
      response_body = { 'result' => 'success' }

      stub_request(:post, "#{@base_url}/test")
        .with(
          body:    request_body.to_json,
          headers: {
            'Accept'        => 'application/json',
            'Authorization' => "Token #{@token}",
            'Content-Type'  => 'application/json',
            'X-Secret'      => @secret
          }
        )
        .to_return(
          status:  200,
          body:    response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = @client.submit('/test', request_body, :post)

      assert_equal response_body, result
    end

    def test_api_error_handling
      stub_request(:get, "#{@base_url}/test")
        .to_return(status: 401)

      error = assert_raises(ApiError) do
        @client.submit('/test', {})
      end

      assert_equal 401, error.status
      assert_match(/Missing API key/, error.message)
    end

    def test_connection_error_handling
      stub_request(:get, "#{@base_url}/test")
        .to_raise(Faraday::ConnectionFailed)

      error = assert_raises(ConnectionError) do
        @client.submit('/test', {})
      end

      assert_match(/Failed to connect/, error.message)
    end

    def test_connection_error_with_sensitive_data
      logger_output = StringIO.new
      Dadata.configure do |config|
        config.logger = Logger.new(logger_output)
      end

      stub_request(:get, "#{@base_url}/test")
        .with(
          headers: {
            'Authorization' => "Token #{@token}",
            'X-Secret'      => @secret
          }
        )
        .to_raise(Faraday::ConnectionFailed.new('Failed to connect'))

      error = assert_raises(Dadata::ConnectionError) do
        @client.send(:submit, 'test', {})
      end

      assert_equal 'Failed to connect', error.message
      log_output = logger_output.string

      # Headers should be sanitized
      assert_match(/Authorization: \[FILTERED\]/, log_output)
      assert_match(/X-Secret: \[FILTERED\]/, log_output)
    end

    def test_rate_limit_error
      stub_request(:get, "#{@base_url}/test")
        .to_return(
          status:  429,
          body:    '{"message": "Too many requests"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      assert_raises(Dadata::RateLimitError) do
        @client.send(:submit, 'test', {})
      end
    end

    def test_authentication_error
      stub_request(:get, "#{@base_url}/test")
        .to_return(
          status:  403,
          body:    '{"message": "Invalid API key"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      assert_raises(Dadata::AuthenticationError) do
        @client.send(:submit, 'test', {})
      end
    end

    def test_retry_on_timeout
      stub_request(:get, "#{@base_url}/test")
        .to_timeout
        .then
        .to_return(
          status:  200,
          body:    { result: 'success' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = @client.submit('/test', {})

      assert_equal({ 'result' => 'success' }, result)
    end

    def test_custom_timeout
      response_body = { 'result' => 'success' }
      stub_request(:get, "#{@base_url}/test")
        .to_return(
          status:  200,
          body:    response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = @client.submit('/test', {}, :get, timeout: 10)

      assert_equal response_body, result
    end
  end
end
