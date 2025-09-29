# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'
require 'json'
require_relative '../sensitive_data'

module Dadata
  # Faraday middleware that handles logging of requests and responses while ensuring
  # sensitive data is properly sanitized. This middleware is automatically added to
  # all DaData API clients.
  #
  # @api private
  class SensitiveDataMiddleware < Faraday::Middleware
    include SensitiveData

    # Processes the request, logs it securely, and handles any errors
    #
    # @param env [Hash] The request environment
    # @return [Faraday::Response] The response from the next middleware
    def call(env)
      log_request(env)
      @app.call(env).on_complete do |response_env|
        log_response(response_env)
      end
    rescue Faraday::Error => e
      log_error(e)
      raise
    end

    private

    # Logs the request details with sensitive data filtered
    #
    # @param env [Hash] The request environment
    # @return [void]
    def log_request(env)
      return unless logger

      logger.debug do
        msg = "DaData Request: #{env.method.upcase} #{env.url}"
        msg += "\nParams: #{env.params.inspect}" if env.params && !env.params.empty?
        msg += "\nHeaders: #{sanitize_headers(env.request_headers)}"
        msg
      end
    end

    # Logs the response details with sensitive data filtered
    #
    # @param env [Hash] The response environment
    # @return [void]
    def log_response(env)
      return unless logger

      logger.debug do
        msg = "DaData Response: #{env.status}"
        msg += "\nHeaders: #{sanitize_headers(env.response_headers)}"
        msg
      end
    end

    # Logs error details with sensitive data filtered
    #
    # @param error [Faraday::Error] The error that occurred
    # @return [void]
    def log_error(error)
      return unless logger

      logger.error do
        msg = "DaData Error: #{error.class.name}"
        msg += "\nMessage: #{sanitize_message(error.message)}"
        msg += "\nHeaders: #{sanitize_headers(error.response[:response_headers] || {})}" if error.response
        msg
      end
    end

    # Gets the logger from the DaData configuration
    #
    # @return [Logger, nil] The configured logger
    def logger
      Dadata.configuration&.logger
    end
  end

  # Base client class that handles HTTP communication with the DaData API.
  # Implements secure logging and request/response handling.
  #
  # @api private
  class ClientBase
    # HTTP status codes and their descriptions
    ERRORS = {
      200 => 'Request processed successfully',
      400 => 'Invalid request (invalid JSON or XML)',
      401 => 'Missing API key or secret key, or non-existent key used',
      403 => 'Invalid API key, unconfirmed email, or daily request limit exceeded',
      404 => 'Service not found',
      405 => 'Request method other than POST used',
      413 => 'Request too long or too many conditions',
      429 => 'Too many requests per second or new connections per minute',
      500 => 'Internal service error'
    }.freeze

    # Creates a new client instance
    #
    # @param base_url [String] The base URL for API requests
    # @param token [String] The API token for authentication
    # @param secret [String, nil] Optional secret key for additional authentication
    def initialize(base_url, token, secret = nil)
      @base_url = base_url
      @token = token
      @secret = secret
      @connection = build_connection
      @logger = Dadata.configuration&.logger
    end

    # Submits a request to the API
    #
    # @param url [String] The endpoint URL
    # @param data [Hash] The request data
    # @param method [Symbol] The HTTP method to use (:get or :post)
    # @param timeout [Integer] Request timeout in seconds
    # @return [Hash] The parsed response
    # @raise [ApiError] If the API returns an error
    # @raise [ConnectionError] If there's a network error
    def submit(url, data, method = :get, timeout: Dadata.timeout_sec)
      log_request(method, url, data)

      response = send_request(url, data, method, timeout)
      handle_response(response)
    rescue Faraday::Error => e
      handle_connection_error(e)
    end

    private

    # Builds the Faraday connection with appropriate middleware and settings
    #
    # @return [Faraday::Connection]
    def build_connection
      require 'faraday/net_http_persistent'

      Faraday.new(@base_url) do |conn|
        conn.request :json
        conn.request :retry, {
          max:                 2,
          interval:            0.05,
          interval_randomness: 0.5,
          backoff_factor:      2,
          exceptions:          [
            Faraday::ConnectionFailed,
            Faraday::TimeoutError,
            'Timeout::Error',
            'Error'
          ]
        }

        conn.use SensitiveDataMiddleware

        conn.response :json, content_type: /\bjson$/

        conn.headers = {
          'Content-Type'  => 'application/json',
          'Accept'        => 'application/json',
          'Authorization' => "Token #{@token}"
        }
        conn.headers['X-Secret'] = @secret if @secret

        conn.adapter :net_http_persistent do |http|
          http.read_timeout = Dadata.configuration&.timeout_sec || 10
          http.open_timeout = Dadata.configuration&.timeout_sec || 10
          http.write_timeout = Dadata.configuration&.timeout_sec || 10
        end
      end
    end

    # Sends a request to the API
    #
    # @param url [String] The endpoint URL
    # @param data [Hash] The request data
    # @param method [Symbol] The HTTP method to use (:get or :post)
    # @param timeout [Integer] Request timeout in seconds
    # @return [Faraday::Response] The response from the API
    def send_request(url, data, method, timeout)
      @connection.public_send(method) do |req|
        req.url(url)
        req.options.timeout = timeout
        req.body = data.to_json unless method == :get
        req.params = data if method == :get
      end
    end

    # Handles the response from the API
    #
    # @param response [Faraday::Response] The response from the API
    # @return [Hash] The parsed response
    # @raise [ApiError] If the API returns an error
    def handle_response(response)
      return response.body if response.success?

      error_message = ERRORS[response.status] || 'Unknown error'
      log_error("API Error: #{error_message} (#{response.status})")

      case response.status
      when 401, 403
        raise AuthenticationError.new(response.status, error_message)
      when 429
        raise RateLimitError.new(response.status, error_message)
      else
        raise ApiError.new(response.status, error_message)
      end
    end

    # Handles connection errors
    #
    # @param error [Faraday::Error] The error that occurred
    # @raise [ConnectionError] If there's a network error
    def handle_connection_error(error)
      sanitized_error = sanitize_error_message(error.message)
      log_error("Connection Error: #{sanitized_error}")
      log_error("Headers: #{sanitize_headers(@connection.headers)}")

      case error
      when Faraday::TimeoutError
        raise ConnectionError, 'Request timed out'
      when Faraday::ConnectionFailed
        raise ConnectionError, 'Failed to connect'
      else
        raise ConnectionError, 'Request failed'
      end
    end

    # Sanitizes error messages to remove sensitive data
    #
    # @param msg [String] The error message
    # @return [String] The sanitized error message
    def sanitize_error_message(msg)
      return '' unless msg.is_a?(String)

      result = msg.dup
      SensitiveDataMiddleware::SENSITIVE_HEADERS.each do |header|
        result = result.gsub(/#{Regexp.escape(header)}[^:\n]*:.*?(?=\n|\z)/, "#{header}: [FILTERED]")
      end
      result
    end

    # Logs a request
    #
    # @param method [Symbol] The HTTP method used
    # @param url [String] The endpoint URL
    # @param data [Hash] The request data
    # @return [void]
    def log_request(method, url, data)
      return unless @logger

      @logger.debug do
        msg = "DaData Request: #{method.upcase} #{url}"
        msg += "\nParams: #{data.inspect}" if data && !data.empty?
        msg += "\nHeaders: #{sanitize_headers(@connection.headers)}"
        msg
      end
    end

    # Logs an error
    #
    # @param message [String] The error message
    # @return [void]
    def log_error(message)
      @logger&.error(sanitize_error_message(message))
    end

    # Sanitizes headers to remove sensitive data
    #
    # @param headers [Hash] The headers to sanitize
    # @return [String] The sanitized headers
    def sanitize_headers(headers)
      return '' unless headers

      headers.map do |key, value|
        if SensitiveDataMiddleware::SENSITIVE_HEADERS.include?(key)
          "#{key}: [FILTERED]"
        else
          "#{key}: #{value}"
        end
      end.join(', ')
    end
  end
end
