# frozen_string_literal: true

require_relative 'base'

module Dadata
  # Client for data cleaning and standardization operations
  class CleanClient < ClientBase
    BASE_URL = 'https://cleaner.dadata.ru/api/v1/'

    def initialize(token = Dadata.api_key, secret = Dadata.secret_key)
      super(BASE_URL, token, secret)
    end

    # Clean and standardize a single value
    #
    # @param name [String] Type of cleaning to apply:
    #   - address - postal address
    #   - phone - phone number
    #   - passport - passport number
    #   - name - full name
    #   - email - email address
    #   - birthdate - date
    #   - vehicle - vehicle brand and model
    #   - simple_party_name - company name
    # @param source [String] Value to clean
    # @return [Hash, nil] Cleaned data or nil if cleaning failed
    def clean(name, source)
      response = submit("clean/#{name}", [source], :post)
      response&.first
    end

    # Clean and standardize a composite record
    #
    # @param structure [Array<String>] Record structure with fields:
    #   - AS_IS - leave as is (no standardization)
    #   - SIMPLE_PARTY_NAME - parse company name
    #   - NAME - parse as full name
    #   - BIRTHDATE - parse as date
    #   - ADDRESS - parse as address
    #   - PHONE - parse as phone
    #   - PASSPORT - passport number
    #   - EMAIL - email address
    #   - VEHICLE - vehicle brand and model
    # @param record [Array<String>] Record to process; field order must match structure
    # @return [Hash, nil] Cleaned data or nil if cleaning failed
    def clean_record(structure, record)
      data = { structure:, data: [record] }
      response = submit('clean', data, :post)
      response&.dig('data', 0)
    end
  end
end
