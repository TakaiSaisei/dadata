# DaData Ruby Client | Клиент DaData для Ruby

[English](#english) | [Русский](#russian)

---

<a name="russian"></a>
# DaData — [неофициальный] Ruby (& Rails) клиент для API DaData.ru

## Описание

Gem для работы с [API DaData.ru](https://dadata.ru/api/). Поддерживает все основные методы API и предоставляет удобную интеграцию с Ruby on Rails.

В качестве отправной точки взята официальная библиотека [для Python](https://github.com/hflabs/dadata-py).

### Основные возможности

- **Стандартизация данных:**
  - Адреса
  - ФИО
  - Телефоны
  - Email
  - Паспортные данные
  - Даты
  - И другие типы данных

- **Подсказки (автодополнение):**
  - Адреса
  - Организации
  - Банки
  - ФИО
  - Email
  - И другие справочники

- **Дополнительные методы:**
  - Геолокация
  - Определение города по IP
  - Поиск аффилированных компаний
  - Работа с балансом и статистикой

## Требования

- Ruby >= 3.3.0

## Установка

Добавьте в Gemfile вашего проекта:

```ruby
gem 'dadata', git: 'https://hub.mos.ru/ad/dadata'
```

Затем выполните:

```bash
bundle install
```

### Поддержка предыдущих версий

Если вам нужно использовать предыдущую версию gem (1.x), вы можете указать ветку `v1.0.0` в вашем Gemfile:

```ruby
gem 'dadata', git: 'https://hub.mos.ru/ad/dadata', branch: 'v1.0.0'
```

Основные отличия версии 2.0.0:
- Переход с `http` на `faraday` для большей гибкости
- Безопасное логирование с автоматической фильтрацией конфиденциальных данных
- Изменен синтаксис конфигурации с хеш-стиля на вызовы методов
- Добавлен пул соединений для улучшения производительности
- Добавлен генератор для Rails с поддержкой credentials

## Конфигурация

### Rails Generator

Для Rails-приложений предусмотрен генератор конфигурации. Запустите:

```bash
rails generate dadata:initializer
```

По умолчанию, генератор создаст:
- Инициализатор `config/initializers/dadata.rb`
- Добавит API-ключи в `credentials.yml.enc`

#### Опции генератора:

```bash
rails generate dadata:initializer [опции]

Опции:
    --api-key=КЛЮЧ          # Ваш API-ключ DaData
    --secret-key=КЛЮЧ       # Ваш секретный ключ DaData
    --[no-]use-credentials  # Использовать ли Rails credentials (по умолчанию: true)
    --timeout=СЕКУНДЫ      # Таймаут запросов (по умолчанию: 3)
    --suggestions-count=N   # Количество подсказок (по умолчанию: 10)
```

### Ручная настройка

```ruby
Dadata.configure do |config|
  # API-ключ из личного кабинета
  config.api_key = 'ВАШ_API_КЛЮЧ'
  
  # Секретный ключ (для некоторых методов)
  config.secret_key = 'ВАШ_СЕКРЕТНЫЙ_КЛЮЧ'
  
  # Таймаут запросов в секундах
  config.timeout_sec = 3
  
  # Количество подсказок в ответе
  config.suggestions_count = 10

  # Размер пула соединений
  config.connection_pool_size = 25

  # Таймаут пула соединений
  config.connection_pool_timeout = 5

  # Уровень логирования (:debug, :info, :warn, :error)
  config.log_level = :info

  # Пользовательский логгер (опционально)
  config.logger = Logger.new('dadata.log')
end
```

### Безопасное логирование

Gem автоматически фильтрует конфиденциальные данные в логах, такие как API-ключи и секретные ключи.
По умолчанию используется встроенный `SecureLogger`, который:

- Фильтрует заголовки `Authorization`, `X-Secret` и `API-Key`
- Заменяет конфиденциальные данные на `[FILTERED]`
- Поддерживает все стандартные уровни логирования

Пример лога запроса:
```
I, [2025-01-25T20:44:10+03:00] INFO -- : DaData Request: POST https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address
Headers: Authorization: [FILTERED], Content-Type: application/json
```

### Пул соединений

Gem использует пул постоянных HTTP-соединений для улучшения производительности. Вы можете настроить:

- `connection_pool_size`: количество одновременных соединений (по умолчанию: 25)
- `connection_pool_timeout`: таймаут ожидания свободного соединения в секундах (по умолчанию: 5)

## Использование

### Общий клиент

```ruby
# Используя настройки из конфигурации
api = Dadata::Client.new

# Или с явным указанием ключей
api = Dadata::Client.new('ВАШ_API_КЛЮЧ', 'ВАШ_СЕКРЕТНЫЙ_КЛЮЧ')
```

### Специализированные клиенты

#### Подсказки (SuggestClient)

```ruby
suggest = Dadata::SuggestClient.new

# Поиск адреса
suggest.suggest("address", "москва хабар")

# Поиск организации
suggest.suggest("party", "сбербанк")

# Поиск банка по БИК или названию
suggest.suggest("bank", "044525225")
```

#### Стандартизация (CleanClient)

```ruby
cleaner = Dadata::CleanClient.new

# Стандартизация адреса
cleaner.clean("address", "мск сухонская 11")

# Стандартизация ФИО
cleaner.clean("name", "иванов сергей")

# Стандартизация телефона
cleaner.clean("phone", "9161234567")
```

#### Профиль (ProfileClient)

```ruby
profile = Dadata::ProfileClient.new

# Проверка баланса
profile.balance

# Статистика использования
profile.daily_stats
```

## Примеры использования

### Стандартизация адреса

```ruby
result = api.clean("address", "мск сухонская 11")
puts result['result']      # Стандартизованный адрес
puts result['postal_code'] # Почтовый индекс
puts result['region']      # Регион
puts result['city']        # Город
```

### Поиск организации по ИНН

```ruby
result = api.suggest("party", "7707083893")
company = result[0]
puts company['value']    # Краткое название
puts company['inn']      # ИНН
puts company['address']  # Адрес
```

### Определение города по IP

```ruby
result = api.iplocate("46.226.227.20")
puts result['value']     # Город
puts result['region']    # Регион
```

## Обработка ошибок

Gem выбрасывает следующие исключения:

```ruby
Dadata::ApiError          # Ошибка API (неверный запрос)
Dadata::ConnectionError   # Ошибка соединения
Dadata::TimeoutError      # Превышен таймаут запроса
```

Рекомендуется обрабатывать их следующим образом:

```ruby
begin
  api.clean("address", "мск сухонская 11")
rescue Dadata::ApiError => e
  puts "Ошибка API: #{e.message}"
rescue Dadata::ConnectionError => e
  puts "Ошибка соединения: #{e.message}"
rescue Dadata::TimeoutError => e
  puts "Таймаут запроса: #{e.message}"
end
```

---

<a name="english"></a>
# DaData — [unofficial] Ruby (& Rails) client for DaData.ru API

## Description

A Ruby gem for working with [DaData.ru API](https://dadata.ru/api/). Supports all main API methods and provides convenient Rails integration.

Based on the official [Python library](https://github.com/hflabs/dadata-py).

### Key Features

- **Data Standardization:**
  - Addresses
  - Names
  - Phone numbers
  - Email
  - Passport data
  - Dates
  - And other data types

- **Suggestions (Autocomplete):**
  - Addresses
  - Organizations
  - Banks
  - Names
  - Email
  - And other reference data

- **Additional Methods:**
  - Geolocation
  - City detection by IP
  - Finding affiliated companies
  - Balance and statistics

## Requirements

- Ruby >= 3.3.0

## Installation

Add to your project's Gemfile:

```ruby
gem 'dadata', git: 'https://hub.mos.ru/ad/dadata'
```

Then run:

```bash
bundle install
```

### Legacy Version Support

If you need to use a previous version of the gem (1.x), you can specify the `v1.0.0` branch in your Gemfile:

```ruby
gem 'dadata', git: 'https://hub.mos.ru/ad/dadata', branch: 'v1.0.0'
```

Key differences in version 2.0.0:
- Replaced `http` gem with `faraday` for better HTTP handling
- Secure logging with automatic filtering of confidential data
- Configuration syntax changed from hash-style to method calls
- Connection pool added for improved performance
- Rails generator added with credentials support

## Configuration

### Rails Generator

For Rails applications, a configuration generator is provided. Run:

```bash
rails generate dadata:initializer
```

By default, the generator will:
- Create initializer at `config/initializers/dadata.rb`
- Add API keys to `credentials.yml.enc`

#### Generator Options:

```bash
rails generate dadata:initializer [options]

Options:
    --api-key=KEY           # Your DaData API key
    --secret-key=KEY        # Your DaData secret key
    --[no-]use-credentials  # Whether to use Rails credentials (default: true)
    --timeout=SECONDS       # Request timeout (default: 3)
    --suggestions-count=N   # Number of suggestions (default: 10)
```

### Manual Configuration

```ruby
Dadata.configure do |config|
  # API key from your account
  config.api_key = 'YOUR_API_KEY'
  
  # Secret key (required for some methods)
  config.secret_key = 'YOUR_SECRET_KEY'
  
  # Request timeout in seconds
  config.timeout_sec = 3
  
  # Number of suggestions in response
  config.suggestions_count = 10

  # Connection pool size
  config.connection_pool_size = 25

  # Connection pool timeout
  config.connection_pool_timeout = 5

  # Log level (:debug, :info, :warn, :error)
  config.log_level = :info

  # Custom logger (optional)
  config.logger = Logger.new('dadata.log')
end
```

### Secure Logging

The gem automatically filters confidential data in logs, such as API keys and secret keys.
By default, the built-in `SecureLogger` is used, which:

- Filters `Authorization`, `X-Secret` and `API-Key` headers
- Replaces confidential data with `[FILTERED]`
- Supports all standard log levels

Example log entry:
```
I, [2025-01-25T20:44:10+03:00] INFO -- : DaData Request: POST https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address
Headers: Authorization: [FILTERED], Content-Type: application/json
```

### Connection Pool

The gem uses a pool of persistent HTTP connections to improve performance. You can configure:

- `connection_pool_size`: number of concurrent connections (default: 25)
- `connection_pool_timeout`: timeout for waiting for a free connection in seconds (default: 5)

## Usage

### General Client

```ruby
# Using configuration settings
api = Dadata::Client.new

# Or with explicit keys
api = Dadata::Client.new('YOUR_API_KEY', 'YOUR_SECRET_KEY')
```

### Specialized Clients

#### Suggestions (SuggestClient)

```ruby
suggest = Dadata::SuggestClient.new

# Address search
suggest.suggest("address", "moscow tverskaya")

# Organization search
suggest.suggest("party", "sberbank")

# Bank search by BIC or name
suggest.suggest("bank", "044525225")
```

#### Standardization (CleanClient)

```ruby
cleaner = Dadata::CleanClient.new

# Address standardization
cleaner.clean("address", "msk suhonskaya 11")

# Name standardization
cleaner.clean("name", "ivanov sergey")

# Phone standardization
cleaner.clean("phone", "9161234567")
```

#### Profile (ProfileClient)

```ruby
profile = Dadata::ProfileClient.new

# Check balance
profile.balance

# Usage statistics
profile.daily_stats
```

## Usage Examples

### Address Standardization

```ruby
result = api.clean("address", "msk suhonskaya 11")
puts result['result']      # Standardized address
puts result['postal_code'] # Postal code
puts result['region']      # Region
puts result['city']        # City
```

### Company Search by Tax ID (INN)

```ruby
result = api.suggest("party", "7707083893")
company = result[0]
puts company['value']    # Short name
puts company['inn']      # Tax ID
puts company['address']  # Address
```

### City Detection by IP

```ruby
result = api.iplocate("46.226.227.20")
puts result['value']     # City
puts result['region']    # Region
```

## Error Handling

The gem raises the following exceptions:

```ruby
Dadata::ApiError          # API error (invalid request)
Dadata::ConnectionError   # Connection error
Dadata::TimeoutError      # Request timeout exceeded
```

It's recommended to handle them as follows:

```ruby
begin
  api.clean("address", "msk suhonskaya 11")
rescue Dadata::ApiError => e
  puts "API Error: #{e.message}"
rescue Dadata::ConnectionError => e
  puts "Connection Error: #{e.message}"
rescue Dadata::TimeoutError => e
  puts "Request Timeout: #{e.message}"
end