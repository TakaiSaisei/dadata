# frozen_string_literal: true

require_relative 'dadata/version'
require_relative 'dadata/api_exceptions'
require_relative 'dadata/sensitive_data'
require_relative 'dadata/client/base'
require_relative 'dadata/client/clean'
require_relative 'dadata/client/suggest'
require_relative 'dadata/client/profile'
require 'logger'

# Ruby wrapper for DaData API
module Dadata
  SUGGESTIONS_COUNT = 10
  TIMEOUT_SEC = 3
  MAX_SUGGESTIONS = 20

  # SecureLogger extends Ruby's Logger class to provide automatic sanitization
  # of sensitive data in log messages. It is used internally by the gem to ensure
  # that sensitive information like API keys and secrets are not exposed in logs.
  #
  # @example
  #   logger = SecureLogger.new($stdout)
  #   logger.info('API-Key: secret123') # Logs: "API-Key: [FILTERED]"
  class SecureLogger < Logger
    include SensitiveData

    # Creates a new SecureLogger instance with a custom formatter that sanitizes
    # sensitive data in log messages.
    #
    # @param logdev [IO, String, nil] The log device to write to
    def initialize(logdev = nil)
      super
      @formatter = proc do |severity, datetime, progname, msg|
        msg = sanitize_message(msg.to_s)
        "I, [#{datetime}]  #{severity} -- #{progname}: #{msg}\n"
      end
    end
  end

  # Configuration class for the DaData API client
  #
  # @example
  #   Dadata.configure do |config|
  #     config.api_key = 'your_api_key'
  #     config.secret_key = 'your_secret_key'
  #     config.timeout_sec = 5
  #   end
  class Configuration
    include SensitiveData

    attr_accessor :api_key, :secret_key, :timeout_sec,
                  :connection_pool_size, :connection_pool_timeout,
                  :log_level
    attr_reader :suggestions_count, :logger

    # Initialize a new Configuration instance with default values
    #
    # @return [Configuration]
    def initialize
      @suggestions_count = SUGGESTIONS_COUNT
      @timeout_sec = TIMEOUT_SEC
      @connection_pool_size = 25
      @connection_pool_timeout = 5
      @log_level = :info
      setup_logger
    end

    # Validates the configuration settings
    #
    # @raise [ConfigurationError] if any settings are invalid
    # @return [void]
    def validate!
      if timeout_sec && timeout_sec <= 0
        raise ConfigurationError, 'Timeout must be positive'
      end
      if suggestions_count && (suggestions_count < 1 || suggestions_count > MAX_SUGGESTIONS)
        raise ConfigurationError, "Suggestions count must be between 1 and #{MAX_SUGGESTIONS}"
      end
      if api_key.nil? || api_key.strip.empty?
        raise ConfigurationError, "API key can't be blank"
      end
    end

    # Sets the suggestions count, enforcing the maximum limit
    #
    # @param value [Integer] The number of suggestions to return
    # @raise [ConfigurationError] if value is less than 1
    # @return [Integer] The actual suggestions count (may be capped at MAX_SUGGESTIONS)
    def suggestions_count=(value)
      return unless value
      if value < 1
        raise ConfigurationError, "Suggestions count must be between 1 and #{MAX_SUGGESTIONS}"
      end

      @suggestions_count = [value, MAX_SUGGESTIONS].min
    end

    # Sets the logger, wrapping it in SecureLogger if necessary
    #
    # @param logger [Logger] The logger to use
    # @return [SecureLogger] The wrapped logger
    def logger=(logger)
      @logger = if logger.is_a?(SecureLogger)
                  logger
                else
                  SecureLogger.new(logger.instance_variable_get(:@logdev))
                end
      @logger.level = logger.level if logger.respond_to?(:level)
    end

    private

    # Sets up the default logger
    #
    # @return [void]
    def setup_logger
      self.logger = Logger.new($stdout)
      @logger.level = log_level || :info
    end
  end

  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def api_key
      configuration&.api_key
    end

    def secret_key
      configuration&.secret_key
    end

    def suggestions_count
      configuration&.suggestions_count || SUGGESTIONS_COUNT
    end

    def timeout_sec
      configuration&.timeout_sec || TIMEOUT_SEC
    end
  end

  # Глобальный клиент к API Dadata
  class Client
    def initialize(token = Dadata.api_key, secret = Dadata.secret_key)
      @cleaner = CleanClient.new(token, secret)
      @suggestions = SuggestClient.new(token, secret)
      @profile = ProfileClient.new(token, secret)
    end

    # Стандартизация. Приводит в порядок и обогащает дополнительной информацией.
    #
    # @param [String] name Тип применяемой стандартизации:
    #   +address+ — адрес,
    #   +phone+ — телефонный номер,
    #   +passport+ — серия и номер паспорта,
    #   +name+ — ФИО,
    #   +email+ — электронная почта,
    #   +birthdate+ — дата,
    #   +vehicle+ — марка автомобиля,
    #   +simple_party_name+ — наименование юрлица
    # @param [String] source Строка, подлежащая обработке
    # @return [Object]
    #
    # @see https://dadata.ru/api/clean/
    # @note 15 коп./запись. Максимальная частота запросов — 20 в секунду с одного IP-адреса.
    # @note Максимальная частота создания новых соединений — 60 в минуту с одного IP-адреса.
    # @note Дадата не поддерживает вызов этого метода из браузерного JavaScript.
    # Иначе злоумышленник мог бы похитить секретный ключ и использовать API за ваш счет.
    def clean(name, source)
      @cleaner.clean(name, source)
    rescue StandardError => e
      Dadata.configuration.logger.error("Error cleaning #{name}: #{e.message}")
      raise
    end

    # Стандартизация составных записей
    #
    # @param [Array<String>] structure Структура записи, содержит поля:
    #   +AS_IS+ — оставить как есть (не стандартизировать),
    #   +SIMPLE_PARTY_NAME+ — разобрать наименование,
    #   +NAME+ — разобрать как ФИО,
    #   +BIRTHDATE+ — разобрать как дату,
    #   +ADDRESS+ — разобрать как адрес,
    #   +PHONE+ — разобрать как телефон,
    #   +PASSPORT+ — номер и серия паспорта,
    #   +EMAIL+ — адрес электронной почты,
    #   +VEHICLE+ — марка и модель автомобиля
    # @param [Array<String>] record Запись, подлежащая обработке; порядок полей должен соответствовать +structure+
    # @return [Object]
    #
    # @see https://dadata.ru/api/clean/record/
    # @note Максимальное количество полей в одной записи:
    #   1 ФИО,
    #   3 адреса,
    #   3 телефона,
    #   3 email,
    #   1 дата рождения,
    #   1 паспорт,
    #   1 автомобиль.
    # @note 15 коп./запись. Максимальная частота запросов — 20 в секунду с одного IP-адреса.
    # @note Максимальная частота создания новых соединений — 60 в минуту с одного IP-адреса.
    # @note Дадата не поддерживает вызов этого метода из браузерного JavaScript.
    # Иначе злоумышленник мог бы похитить секретный ключ и использовать API за ваш счет.
    def clean_record(structure, record)
      @cleaner.clean_record(structure, record)
    rescue StandardError => e
      Dadata.configuration.logger.error("Error cleaning record: #{e.message}")
      raise
    end

    # Обратное геокодирование (адрес по координатам)
    #
    # @param [String<address|postal_unit>] name Тип поиска
    # @param [Numeric] lat Географическая широта
    # @param [Numeric] lon Географическая долгота
    # @param [Integer] radius_meters Радиус поиска в метрах, опционально, default 100, max 1000
    # @param [Integer] **kwargs(:count) Количество результатов, опционально, default 10, max 20
    # @param [String<ru|en>] **kwargs(:language) На каком языке вернуть результат, опционально, default "ru"
    # @return [Object]
    #
    # @see https://dadata.ru/api/geolocate/
    # @see https://dadata.ru/api/suggest/postal_unit/
    # @note Метод бесплатный до 10000 запросов в день, или в соответствии с тарифным планом.
    # @note Максимальная частота запросов — 30 в секунду с одного IP-адреса.
    # @note Максимальная частота создания новых соединений — 60 в минуту с одного IP-адреса.
    def geolocate(name, lat, lon, radius_meters = 100, **)
      @suggestions.geolocate(name, lat, lon, radius_meters, **)
    rescue StandardError => e
      Dadata.configuration.logger.error("Error geolocating: #{e.message}")
      raise
    end

    # Город по IP-адресу
    #
    # @param [String] ip IP-адрес
    # @param [String<ru|en>] **kwargs(:language) На каком языке вернуть результат, опционально, default "ru"
    # @return [Object]
    #
    # @see https://dadata.ru/api/iplocate/
    # @note Метод бесплатный до 10000 запросов в день, или в соответствии с тарифным планом.
    # @note Максимальная частота запросов — 30 в секунду с одного IP-адреса.
    # @note Максимальная частота создания новых соединений — 60 в минуту с одного IP-адреса.
    def iplocate(ip, **)
      @suggestions.iplocate(ip, **)
    rescue StandardError => e
      Dadata.configuration.logger.error("Error iplocating: #{e.message}")
      raise
    end

    # Подсказки
    #
    # @param [String] name Тип применяемой подсказки:
    #   +address+ — адрес,
    #   +postal_unit+ — почтовое отделение,
    #   +party+ — организация,
    #   +bank+ — банк,
    #   +fio+ — ФИО,
    #   +fms_unit+ — отделение ФМС,
    #   +email+ — адрес электронной почты,
    #   +car_brand+ — марка автомобиля,
    #   +fns_unit+ — отделение ФНС,
    #   +fts_unit+ — отделение ФТС,
    #   +region_court+ — отделение регионального суда,
    #   +country+ — страны,
    #   +metro+ — станция метро,
    #   +mktu+ — классификатор МКТУ,
    #   +currency+ — справочник валют,
    #   +okved2+ — классификатор ОКВЭД 2,
    #   +okpd2+ — классификатор ОКПД 2
    # @param [String] query Текст запроса
    # @param [Integer] count Количество результатов, опционально, default 10, max 20
    # @param [Array<Object>] **kwargs(:filters) фильтрация результата (не для всех `name`), опционально
    # @param [String<ru|en>] **kwargs(:language) На каком языке вернуть результат, опционально, default "ru"
    # @return [Object]
    #
    # @see https://dadata.ru/api/find-address
    # @see https://dadata.ru/api/suggest/postal_unit
    # @see https://dadata.ru/api/suggest/party
    # @see https://dadata.ru/api/suggest/bank
    # @see https://dadata.ru/api/suggest/name
    # @see https://dadata.ru/api/suggest/fms_unit
    # @see https://dadata.ru/api/suggest/email
    # @see https://dadata.ru/api/suggest/car_brand
    # @see https://dadata.ru/api/suggest/fns_unit
    # @see https://dadata.ru/api/suggest/fts_unit
    # @see https://dadata.ru/api/suggest/region_court
    # @see https://dadata.ru/api/suggest/country
    # @see https://dadata.ru/api/suggest/metro
    # @see https://dadata.ru/api/suggest/mktu
    # @see https://dadata.ru/api/suggest/currency
    # @see https://dadata.ru/api/suggest/okved2
    # @see https://dadata.ru/api/suggest/okpd2
    # @note Длина запроса (параметр query) — не более 300 символов.
    # @note Метод бесплатный до 10000 запросов в день, или в соответствии с тарифным планом.
    # @note Максимальная частота запросов — 30 в секунду с одного IP-адреса.
    # @note Максимальная частота создания новых соединений — 60 в минуту с одного IP-адреса.
    def suggest(name, query, count = Dadata.suggestions_count, **)
      @suggestions.suggest(name, query, [count, MAX_SUGGESTIONS].min, **)
    rescue StandardError => e
      Dadata.configuration.logger.error("Error suggesting: #{e.message}")
      raise
    end

    # Поиск по коду
    #
    # @param [String] name Тип стандартизации:
    #   +address+ — адрес,
    #   +postal_unit+ — почтовое отделение,
    #   +party+ — организация,
    #   +bank+ — банк,
    #   +fms_unit+ — отделение ФМС,
    #   +car_brand+ — марка автомобиля,
    #   +fns_unit+ — отделение ФНС,
    #   +fts_unit+ — отделение ФТС,
    #   +region_court+ — отделение регионального суда,
    #   +delivery+ — идентификатор города в СДЭК, Boxberry и DPD,
    #   +country+ — справочник стран,
    #   +mktu+ — классификатор МКТУ,
    #   +currency+ — справочник валют,
    #   +okved2+ — классификатор ОКВЭД 2,
    #   +okpd2+ — классификатор ОКПД 2,
    #   +oktmo+ — классификатор ОКТМО
    # @param [String] query Текст запроса, обязательно
    # @param [Integer] count Количество результатов, опционально, default 10
    # @param [String] **kwargs(:kpp) поиск по филиалам для `party`, опционально
    # @param [String<MAIN|BRANCH>] **kwargs(:branch_type) тип филиала для `party`, опционально
    # @param [String<LEGAL|INDIVIDUAL>] **kwargs(:type) юрлицо или ИП для `party`, опционально
    # @param [Array<String>] **kwargs(:status) status для `party`, опционально
    # @param [String<ru|en>] **kwargs(:language) На каком языке вернуть результат (не для всех `name`), опционально, default ru
    # @return [Object]
    #
    # @see https://dadata.ru/api/find-address
    # @see https://dadata.ru/api/suggest/postal_unit
    # @see https://dadata.ru/api/find-party
    # @see https://dadata.ru/api/find-bank
    # @see https://dadata.ru/api/suggest/fms_unit
    # @see https://dadata.ru/api/suggest/car_brand
    # @see https://dadata.ru/api/suggest/fns_unit
    # @see https://dadata.ru/api/suggest/fts_unit
    # @see https://dadata.ru/api/suggest/region_court
    # @see https://dadata.ru/api/delivery
    # @see https://dadata.ru/api/suggest/country
    # @see https://dadata.ru/api/suggest/mktu
    # @see https://dadata.ru/api/suggest/currency
    # @see https://dadata.ru/api/suggest/okved2
    # @see https://dadata.ru/api/suggest/okpd2
    # @see https://dadata.ru/api/suggest/oktmo
    # @note Длина запроса (параметр query) — не более 300 символов.
    # @note Метод бесплатный до 10000 запросов в день, или в соответствии с тарифным планом.
    # @note Максимальная частота запросов — 30 в секунду с одного IP-адреса.
    # @note Максимальная частота создания новых соединений — 60 в минуту с одного IP-адреса.
    def find_by_id(name, query, count = Dadata.suggestions_count, **)
      @suggestions.find_by_id(name, query, [count, MAX_SUGGESTIONS].min, **)
    rescue StandardError => e
      Dadata.configuration.logger.error("Error finding by id: #{e.message}")
      raise
    end

    # Компания по email
    #
    # @param [String] query, Текст запроса
    # @return [Array<Object>]
    #
    # @see https://dadata.ru/api/find-company/by-email/
    # @note Длина запроса (параметр query) — не более 300 символов.
    # @note 5 руб./запрос. Количество запросов — в соответствии с тарифным планом.
    # @note Максимальная частота запросов — 30 в секунду с одного IP-адреса.
    # @note Максимальная частота создания новых соединений — 60 в минуту с одного IP-адреса.
    def find_by_email(query)
      @suggestions.find_by_email(query)
    rescue StandardError => e
      Dadata.configuration.logger.error("Error finding by email: #{e.message}")
      raise
    end

    # Поиск аффилированных компаний
    #
    # @param [String] query, Текст запроса
    # @param [Integer] count Количество результатов, опционально, default 10
    # @param [Array<String>] **kwargs(:scope), Где искать, опционально, default ["FOUNDERS", "MANAGERS"]
    # @return [Object]
    #
    # @see https://dadata.ru/api/find-affiliated/
    # @note Доступно только на тарифе «Максимальный»
    # @note Длина запроса (параметр query) — не более 300 символов.
    # @note Количество запросов — в соответствии с тарифным планом.
    # @note Максимальная частота запросов — 30 в секунду с одного IP-адреса.
    # @note Максимальная частота создания новых соединений — 60 в минуту с одного IP-адреса.
    def find_affiliated(query, count = Dadata.suggestions_count, **)
      @suggestions.find_affiliated(query, [count, MAX_SUGGESTIONS].min, **)
    rescue StandardError => e
      Dadata.configuration.logger.error("Error finding affiliated: #{e.message}")
      raise
    end

    # Баланс пользователя
    #
    # @see https://dadata.ru/api/balance
    def balance
      @profile.balance
    rescue StandardError => e
      Dadata.configuration.logger.error("Error getting balance: #{e.message}")
      raise
    end

    # Статистика использования
    #
    # @see https://dadata.ru/api/stat
    def daily_stats(date = nil)
      @profile.daily_stats(date)
    rescue StandardError => e
      Dadata.configuration.logger.error("Error getting daily stats: #{e.message}")
      raise
    end

    # Версии справочников
    #
    # @see https://dadata.ru/api/version
    def versions
      @profile.versions
    rescue StandardError => e
      Dadata.configuration.logger.error("Error getting versions: #{e.message}")
      raise
    end

    def close
      @cleaner.close
      @suggestions.close
      @profile.close
    rescue StandardError => e
      Dadata.configuration.logger.error("Error closing client: #{e.message}")
      raise
    end
  end
end
