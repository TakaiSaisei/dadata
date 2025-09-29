# frozen_string_literal: true

module Dadata
  # The SensitiveData module provides functionality for sanitizing sensitive information
  # in log messages and HTTP headers. It is used internally by the gem to ensure that
  # sensitive data such as API keys and secrets are not exposed in logs.
  #
  # @example
  #   class MyLogger
  #     include SensitiveData
  #
  #     def log_request(headers)
  #       puts sanitize_headers(headers)
  #     end
  #   end
  module SensitiveData
    # List of headers that contain sensitive information and should be filtered
    SENSITIVE_HEADERS = %w[Authorization X-Secret API-Key].freeze

    # Sanitizes headers by replacing sensitive values with [FILTERED]
    #
    # @param headers [Hash, nil] Headers to sanitize
    # @return [String] Sanitized headers string
    # @example
    #   headers = { 'API-Key' => 'secret', 'Content-Type' => 'application/json' }
    #   sanitize_headers(headers) # => "API-Key: [FILTERED], Content-Type: application/json"
    def sanitize_headers(headers)
      return '' unless headers

      headers.map do |key, value|
        if SENSITIVE_HEADERS.include?(key)
          "#{key}: [FILTERED]"
        else
          "#{key}: #{value}"
        end
      end.join(', ')
    end

    # Sanitizes a message by replacing sensitive information with [FILTERED]
    #
    # @param msg [String, nil] Message to sanitize
    # @return [String] Sanitized message
    # @example
    #   msg = "API-Key: secret123, Content-Type: application/json"
    #   sanitize_message(msg) # => "API-Key: [FILTERED], Content-Type: application/json"
    def sanitize_message(msg)
      return '' unless msg.is_a?(String)

      result = msg.dup
      SENSITIVE_HEADERS.each do |header|
        # Escape hyphens in the header name and handle any whitespace around the colon
        pattern = /#{Regexp.escape(header)}[\s]*:[\s]*[^\n,]+/
        result = result.gsub(pattern, "#{header}: [FILTERED]")
      end
      result
    end
  end
end
