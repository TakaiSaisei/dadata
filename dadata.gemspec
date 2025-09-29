# frozen_string_literal: true

require_relative 'lib/dadata/version'

Gem::Specification.new do |spec|
  spec.name = 'dadata'
  spec.version = Dadata::VERSION
  spec.authors = ['Alexander Dryzhuk']
  spec.email = ['ad@ad-it.pro']

  spec.summary = 'Ruby wrapper for Dadata API with secure logging and connection pooling'
  spec.description = <<~DESC
    Ruby wrapper for data cleansing, enrichment and suggestions via [Dadata API](https://dadata.ru/api).
    Features secure logging with automatic filtering of sensitive data, connection pooling,
    and comprehensive Rails integration.

    Библиотека для очистки, обогащения и подсказок при вводе данных с помощью [Dadata API](https://dadata.ru/api).
    Включает безопасное логирование с автоматической фильтрацией конфиденциальных данных,
    пул соединений и полную интеграцию с Rails.
  DESC

  spec.homepage = 'https://hub.mos.ru/ad/dadata'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.3.0')

  # spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://hub.mos.ru/ad/dadata'
  spec.metadata['changelog_uri'] = 'https://hub.mos.ru/ad/dadata/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['documentation_uri'] = 'https://hub.mos.ru/ad/dadata/blob/main/README.md'
  spec.metadata['bug_tracker_uri'] = 'https://hub.mos.ru/ad/dadata/issues'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 2.9'
  spec.add_dependency 'faraday-net_http_persistent', '~> 2.3'
  spec.add_dependency 'faraday-retry', '~> 2.2'
  spec.add_dependency 'net-http-persistent', '~> 4.0'
  spec.add_dependency 'zeitwerk', '~> 2.6'
end
