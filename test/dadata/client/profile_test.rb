# frozen_string_literal: true

require_relative '../../test_helper'

module Dadata
  class ProfileClientTest < Minitest::Test
    def setup
      super
      @client = ProfileClient.new('test_token', 'test_secret')
    end

    def test_balance
      response_body = {
        'balance' => 9999.99
      }

      stub_request(:get, "#{ProfileClient::BASE_URL}profile/balance")
        .with(
          headers: {
            'Authorization' => 'Token test_token',
            'X-Secret'      => 'test_secret'
          }
        )
        .to_return(
          status:  200,
          body:    response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = @client.balance

      assert_equal response_body['balance'], result
    end

    def test_daily_stats
      date = '2024-01-01'
      response_body = {
        'date'     => date,
        'services' => {
          'clean'       => 10,
          'suggestions' => 150,
          'merging'     => 5
        }
      }

      stub_request(:get, "#{ProfileClient::BASE_URL}stat/daily")
        .with(
          query:   { date: Date.parse(date).iso8601 },
          headers: {
            'Authorization' => 'Token test_token',
            'X-Secret'      => 'test_secret'
          }
        )
        .to_return(
          status:  200,
          body:    response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = @client.daily_stats(date)

      assert_equal response_body, result
    end

    def test_daily_stats_with_invalid_date
      response_body = {
        'date'     => Date.today.iso8601,
        'services' => {
          'clean'       => 10,
          'suggestions' => 150,
          'merging'     => 5
        }
      }

      stub_request(:get, "#{ProfileClient::BASE_URL}stat/daily")
        .with(
          query:   { date: Date.today.iso8601 },
          headers: {
            'Authorization' => 'Token test_token',
            'X-Secret'      => 'test_secret'
          }
        )
        .to_return(
          status:  200,
          body:    response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = @client.daily_stats('invalid date')

      assert_equal response_body, result
    end

    def test_versions
      response_body = {
        'suggestions' => {
          'version'   => '4.1',
          'resources' => %w[address party bank email]
        },
        'cleaner'     => {
          'version'   => '1.0',
          'resources' => %w[address phone name email dates]
        }
      }

      stub_request(:get, "#{ProfileClient::BASE_URL}version")
        .with(
          headers: {
            'Authorization' => 'Token test_token',
            'X-Secret'      => 'test_secret'
          }
        )
        .to_return(
          status:  200,
          body:    response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = @client.versions

      assert_equal response_body, result
    end

    def test_error_handling
      stub_request(:get, "#{ProfileClient::BASE_URL}profile/balance")
        .to_return(status: 401)

      assert_raises(ApiError) do
        @client.balance
      end
    end

    def test_empty_response
      stub_request(:get, "#{ProfileClient::BASE_URL}profile/balance")
        .to_return(
          status:  200,
          body:    {}.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = @client.balance

      assert_nil result
    end
  end
end
