# frozen_string_literal: true

require_relative 'base'

module Dadata
  # Client for data suggestions and lookups
  class SuggestClient < ClientBase
    BASE_URL = 'https://suggestions.dadata.ru/suggestions/api/4_1/rs/'

    def initialize(token = Dadata.api_key, secret = Dadata.secret_key)
      super(BASE_URL, token, secret)
    end

    # Find addresses by geographic coordinates
    #
    # @param name [String] Type of entity to search for (e.g., 'address', 'postal_unit')
    # @param lat [Numeric] Latitude
    # @param lon [Numeric] Longitude
    # @param radius_meters [Integer] Search radius in meters (default: 100, max: 1000)
    # @param kwargs [Hash] Additional parameters (e.g., language, count)
    # @return [Array<Hash>, nil] List of suggestions or nil if not found
    def geolocate(name, lat, lon, radius_meters = 100, **kwargs)
      data = { lat:, lon:, radius_meters: }.merge(kwargs)
      response = submit("geolocate/#{name}", data, :post)
      response&.fetch('suggestions', nil)
    end

    # Get address by IP
    #
    # @param query [String] IP address
    # @param kwargs [Hash] Additional parameters (e.g., language)
    # @return [Hash, nil] Location data or nil if not found
    def iplocate(query, **kwargs)
      data = { ip: query }.merge(kwargs)
      response = submit('iplocate/address', data, :get)
      response&.fetch('location', nil)
    end

    # Get suggestions for partial input
    #
    # @param name [String] Type of entity to search for
    # @param query [String] Search query
    # @param count [Integer] Maximum number of results
    # @param kwargs [Hash] Additional parameters (e.g., language, constraints)
    # @return [Array<Hash>, nil] List of suggestions or nil if not found
    def suggest(name, query, count = Dadata.suggestions_count, **kwargs)
      data = { query:, count: }.merge(kwargs)
      response = submit("suggest/#{name}", data, :post)
      response&.fetch('suggestions', nil)
    end

    # Find entities by identifier
    #
    # @param name [String] Type of entity to search for
    # @param query [String] Entity identifier
    # @param count [Integer] Maximum number of results
    # @param kwargs [Hash] Additional parameters (e.g., language)
    # @return [Array<Hash>, nil] List of suggestions or nil if not found
    def find_by_id(name, query, count = Dadata.suggestions_count, **kwargs)
      data = { query:, count: }.merge(kwargs)
      response = submit("findById/#{name}", data, :post)
      response&.fetch('suggestions', nil)
    end

    # Find companies by email address
    #
    # @param query [String] Email address
    # @return [Array<Hash>, nil] List of companies or nil if not found
    def find_by_email(query)
      response = submit('findByEmail/company', { query: }, :post)
      response&.fetch('suggestions', nil)
    end

    # Find affiliated companies
    #
    # @param query [String] Company identifier
    # @param count [Integer] Maximum number of results
    # @param kwargs [Hash] Additional parameters (e.g., scope, type)
    # @return [Array<Hash>, nil] List of affiliated companies or nil if not found
    def find_affiliated(query, count = Dadata.suggestions_count, **kwargs)
      data = { query:, count: }.merge(kwargs)
      response = submit('findAffiliated/party', data, :post)
      response&.fetch('suggestions', nil)
    end
  end
end
