# frozen_string_literal: true

require_relative '../../test_helper'

module Dadata
  class CleanClientTest < Minitest::Test
    def setup
      super
      @client = CleanClient.new('test_token', 'test_secret')
    end

    def test_clean_address
      response_body = [{
        'source'      => 'мск сухонска 11/-89',
        'result'      => 'г Москва, ул Сухонская, д 11, кв 89',
        'postal_code' => '127642',
        'country'     => 'Россия',
        'region'      => 'Москва',
        'city'        => 'Москва',
        'street'      => 'Сухонская',
        'house'       => '11',
        'flat'        => '89'
      }]

      stub_request(:post, "#{CleanClient::BASE_URL}clean/address")
        .with(
          body:    ['мск сухонска 11/-89'].to_json,
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

      result = @client.clean('address', 'мск сухонска 11/-89')

      assert_equal response_body.first, result
    end

    def test_clean_record
      structure = %w[NAME ADDRESS]
      record = ['Сергей Иванов', 'мск сухонска 11/-89']
      response_body = {
        'structure' => structure,
        'data'      => [{
          'name'    => {
            'source' => 'Сергей Иванов',
            'result' => 'Иванов Сергей',
            'first'  => 'Сергей',
            'last'   => 'Иванов'
          },
          'address' => {
            'source' => 'мск сухонска 11/-89',
            'result' => 'г Москва, ул Сухонская, д 11, кв 89'
          }
        }]
      }

      stub_request(:post, "#{CleanClient::BASE_URL}clean")
        .with(
          body:    {
            structure: structure,
            data:      [record]
          }.to_json,
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

      result = @client.clean_record(structure, record)

      assert_equal response_body['data'].first, result
    end

    def test_clean_with_error
      stub_request(:post, "#{CleanClient::BASE_URL}clean/address")
        .to_return(status: 400)

      assert_raises(ApiError) do
        @client.clean('address', 'invalid')
      end
    end

    def test_clean_with_empty_response
      stub_request(:post, "#{CleanClient::BASE_URL}clean/address")
        .to_return(
          status:  200,
          body:    [].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = @client.clean('address', 'not found')

      assert_nil result
    end
  end
end
