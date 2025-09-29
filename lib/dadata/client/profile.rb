# frozen_string_literal: true

require_relative 'base'
require 'date'

module Dadata
  # Client for managing DaData subscriber profile
  class ProfileClient < ClientBase
    BASE_URL = 'https://dadata.ru/api/v2/'

    def initialize(token = Dadata.api_key, secret = Dadata.secret_key)
      super(BASE_URL, token, secret)
    end

    # Get current balance
    #
    # @return [Numeric, nil] Current balance or nil if request failed
    def balance
      response = submit('profile/balance', {}, :get)
      response&.fetch('balance', nil)
    end

    # Get daily statistics
    #
    # @param date [String, nil] Date to get statistics for (ISO 8601 format)
    # @return [Hash, nil] Daily statistics or nil if request failed
    def daily_stats(date = nil)
      date = date.nil? ? Date.today : handle_date(date)
      submit('stat/daily', { date: date.iso8601 }, :get)
    end

    # Get API versions
    #
    # @return [Hash, nil] Version information or nil if request failed
    def versions
      submit('version', {}, :get)
    end

    private

    # Convert string to Date object
    #
    # @param date_string [String] Date string in any parseable format
    # @return [Date] Parsed date or today's date if parsing fails
    def handle_date(date_string)
      Date.parse(date_string.to_s)
    rescue ArgumentError, TypeError
      Date.today
    end
  end
end
