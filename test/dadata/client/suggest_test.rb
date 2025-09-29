# frozen_string_literal: true

require_relative '../../test_helper'

module Dadata
  class SuggestClientTest < Minitest::Test
    def setup
      super
      @client = SuggestClient.new('test_token', 'test_secret')
    end

    def test_geolocate
      response_body = {
        'suggestions' => [{
          'value'              => 'г Москва, ул Сухонская, д 11',
          'unrestricted_value' => 'г Москва, ул Сухонская, д 11',
          'data'               => {
            'postal_code' => '127642',
            'country'     => 'Россия',
            'region'      => 'Москва',
            'city'        => 'Москва',
            'street'      => 'Сухонская',
            'house'       => '11'
          }
        }]
      }

      stub_request(:post, "#{SuggestClient::BASE_URL}geolocate/address")
        .with(
          body:    {
            lat:           55.878,
            lon:           37.653,
            radius_meters: 100
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

      result = @client.geolocate('address', 55.878, 37.653)

      assert_equal response_body['suggestions'], result
    end

    def test_iplocate
      response_body = {
        'location' => {
          'value' => 'г Москва',
          'data'  => {
            'postal_code' => nil,
            'country'     => 'Россия',
            'region'      => 'Москва',
            'city'        => 'Москва'
          }
        }
      }

      stub_request(:get, "#{SuggestClient::BASE_URL}iplocate/address")
        .with(
          query:   { ip: '8.8.8.8' },
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

      result = @client.iplocate('8.8.8.8')

      assert_equal response_body['location'], result
    end

    def test_suggest
      response_body = {
        'suggestions' => [{
          'value'              => 'г Москва, ул Сухонская',
          'unrestricted_value' => 'г Москва, ул Сухонская',
          'data'               => {
            'postal_code' => nil,
            'country'     => 'Россия',
            'region'      => 'Москва',
            'city'        => 'Москва',
            'street'      => 'Сухонская'
          }
        }]
      }

      stub_request(:post, "#{SuggestClient::BASE_URL}suggest/address")
        .with(
          body:    {
            query: 'сухонская',
            count: Dadata.suggestions_count
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

      result = @client.suggest('address', 'сухонская')

      assert_equal response_body['suggestions'], result
    end

    def test_find_by_id
      response_body = {
        'suggestions' => [{
          'value'              => 'ПАО СБЕРБАНК',
          'unrestricted_value' => 'ПАО СБЕРБАНК',
          'data'               => {
            'inn'  => '7707083893',
            'kpp'  => '773601001',
            'ogrn' => '1027700132195',
            'name' => {
              'short_with_opf' => 'ПАО СБЕРБАНК',
              'full_with_opf'  => 'ПУБЛИЧНОЕ АКЦИОНЕРНОЕ ОБЩЕСТВО "СБЕРБАНК РОССИИ"'
            }
          }
        }]
      }

      stub_request(:post, "#{SuggestClient::BASE_URL}findById/party")
        .with(
          body:    {
            query: '7707083893',
            count: Dadata.suggestions_count
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

      result = @client.find_by_id('party', '7707083893')

      assert_equal response_body['suggestions'], result
    end

    def test_find_by_email
      response_body = {
        'suggestions' => [{
          'value'              => 'ООО "ЯНДЕКС"',
          'unrestricted_value' => 'ООО "ЯНДЕКС"',
          'data'               => {
            'inn'  => '7736207543',
            'kpp'  => '770401001',
            'ogrn' => '1027700229193',
            'name' => {
              'short_with_opf' => 'ООО "ЯНДЕКС"',
              'full_with_opf'  => 'ОБЩЕСТВО С ОГРАНИЧЕННОЙ ОТВЕТСТВЕННОСТЬЮ "ЯНДЕКС"'
            }
          }
        }]
      }

      stub_request(:post, "#{SuggestClient::BASE_URL}findByEmail/company")
        .with(
          body:    {
            query: 'info@yandex.ru'
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

      result = @client.find_by_email('info@yandex.ru')

      assert_equal response_body['suggestions'], result
    end

    def test_find_affiliated
      response_body = {
        'suggestions' => [{
          'value'              => 'ООО "ЯНДЕКС.ТАКСИ"',
          'unrestricted_value' => 'ООО "ЯНДЕКС.ТАКСИ"',
          'data'               => {
            'inn'  => '7704340310',
            'kpp'  => '770401001',
            'ogrn' => '1157746017260',
            'name' => {
              'short_with_opf' => 'ООО "ЯНДЕКС.ТАКСИ"',
              'full_with_opf'  => 'ОБЩЕСТВО С ОГРАНИЧЕННОЙ ОТВЕТСТВЕННОСТЬЮ "ЯНДЕКС.ТАКСИ"'
            }
          }
        }]
      }

      stub_request(:post, "#{SuggestClient::BASE_URL}findAffiliated/party")
        .with(
          body:    {
            query: '7736207543',
            count: Dadata.suggestions_count
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

      result = @client.find_affiliated('7736207543')

      assert_equal response_body['suggestions'], result
    end

    def test_error_handling
      stub_request(:post, "#{SuggestClient::BASE_URL}suggest/address")
        .to_return(status: 401)

      assert_raises(ApiError) do
        @client.suggest('address', 'test')
      end
    end

    def test_empty_response
      stub_request(:post, "#{SuggestClient::BASE_URL}suggest/address")
        .to_return(
          status:  200,
          body:    { suggestions: [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = @client.suggest('address', 'not found')

      assert_empty result
    end
  end
end
