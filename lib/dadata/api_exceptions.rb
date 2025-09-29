# frozen_string_literal: true

module Dadata
  # Базовый класс обработки ошибок
  class Error < StandardError; end
  class ConfigurationError < Error; end

  class ApiError < Error
    attr_accessor :status
    attr_reader :message

    def initialize(status, message)
      @status = status
      @message = message
      super("Error: #{status} - #{message}")
    end
  end

  class ConnectionError < Error
    attr_reader :message

    def initialize(message)
      @message = message
      super
    end
  end

  class RateLimitError < ApiError; end
  class AuthenticationError < ApiError; end

  class UnauthorizedError < ApiError; end
  class NotFoundError < ApiError; end
  class BadRequestError < ApiError; end
end
