# frozen_string_literal: true

require_relative '../test_helper'
require 'rails/generators'
require 'generators/dadata/initializer_generator'

class InitializerGeneratorTest < Rails::Generators::TestCase
  tests Dadata::Generators::InitializerGenerator

  class TestApplication
    class << self
      attr_accessor :root, :credentials
    end
  end

  # Struct for mocking Rails credentials
  Credentials = Struct.new(:content_path, :key_path, :config_path, :dadata) do
    def respond_to?(method_name)
      members.include?(method_name) || super
    end
  end

  DadataConfig = Struct.new(:api_key, :secret_key)

  def setup
    @destination_root = File.expand_path('tmp/generators', __dir__)
    prepare_destination
    setup_test_app
  end

  def teardown
    FileUtils.rm_rf(@destination_root)
    TestApplication.root = nil
    TestApplication.credentials = nil
  end

  # Setup methods
  def setup_test_app
    require 'rails/all'

    TestApplication.root = Pathname.new(@destination_root)
    TestApplication.credentials = Credentials.new(
      Pathname.new(File.join(@destination_root, 'config/credentials.yml.enc')),
      Pathname.new(File.join(@destination_root, 'config/master.key')),
      Pathname.new(File.join(@destination_root, 'config/credentials.yml.enc')),
      DadataConfig.new(nil, nil)
    )

    Rails.singleton_class.send(:attr_accessor, :application) unless Rails.respond_to?(:application)
    Rails.application = TestApplication
  end

  test 'generator creates standard initializer without credentials' do
    run_generator ['--no-use-credentials']

    assert_file 'config/initializers/dadata.rb' do |content|
      assert_match(/Dadata\.configure do \|config\|/, content)
      assert_match(/config\.api_key = 'DADATA_API_KEY'/, content)
      assert_match(/config\.secret_key = 'DADATA_SECRET_KEY'/, content)
      assert_match(/config\.timeout_sec = 3/, content)
      assert_match(/config\.suggestions_count = 10/, content)
    end
  end

  test 'generator creates initializer with custom options without credentials' do
    run_generator ['--no-use-credentials', '--api-key=custom_key', '--secret-key=custom_secret']

    assert_file 'config/initializers/dadata.rb' do |content|
      assert_match(/Dadata\.configure do \|config\|/, content)
      assert_match(/config\.api_key = 'custom_key'/, content)
      assert_match(/config\.secret_key = 'custom_secret'/, content)
    end
  end

  test 'generator creates credentials-based initializer' do
    run_generator ['--use-credentials']

    assert_file 'config/initializers/dadata.rb' do |content|
      assert_match(/Dadata\.configure do \|config\|/, content)
      assert_match(/config\.api_key = credentials\.api_key/, content)
      assert_match(/config\.secret_key = credentials\.secret_key/, content)
    end

    credentials_content = File.read(Rails.application.credentials.config_path)

    assert_match(/dadata:/, credentials_content)
    assert_match(/api_key: DADATA_API_KEY/, credentials_content)
    assert_match(/secret_key: DADATA_SECRET_KEY/, credentials_content)
  end

  test 'generator skips credentials update if they already exist' do
    existing_credentials = <<~YAML
      dadata:
        api_key: existing_key
        secret_key: existing_secret
    YAML

    FileUtils.mkdir_p(File.dirname(Rails.application.credentials.config_path))
    File.write(Rails.application.credentials.config_path, existing_credentials)

    run_generator ['--use-credentials']

    assert_file 'config/initializers/dadata.rb' do |content|
      assert_match(/Dadata\.configure do \|config\|/, content)
      assert_match(/config\.api_key = credentials\.api_key/, content)
      assert_match(/config\.secret_key = credentials\.secret_key/, content)
    end

    credentials_content = File.read(Rails.application.credentials.config_path)

    assert_equal existing_credentials, credentials_content
  end

  test 'generator handles missing credentials file' do
    FileUtils.rm_f(Rails.application.credentials.config_path)

    run_generator ['--use-credentials', '--api-key=new_key', '--secret-key=new_secret']

    assert_file 'config/initializers/dadata.rb' do |content|
      assert_match(/Dadata\.configure do \|config\|/, content)
      assert_match(/config\.api_key = credentials\.api_key/, content)
      assert_match(/config\.secret_key = credentials\.secret_key/, content)
    end

    assert_path_exists Rails.application.credentials.config_path
    credentials_content = File.read(Rails.application.credentials.config_path)

    assert_match(/dadata:/, credentials_content)
    assert_match(/api_key: new_key/, credentials_content)
    assert_match(/secret_key: new_secret/, credentials_content)
  end

  test 'generator creates initializer with proper documentation' do
    run_generator ['--no-use-credentials']

    assert_file 'config/initializers/dadata.rb' do |content|
      assert_match(/Конфигурация клиента DaData API/, content)
      assert_match(/Этот файл создан генератором dadata:initializer/, content)
      assert_match(/настройки для работы с API DaData/, content)
      assert_match(/Ваш API-ключ DaData/, content)
      assert_match(/Можно получить в личном кабинете/, content)
    end
  end

  test 'generator creates credentials-based initializer with proper documentation' do
    run_generator ['--use-credentials']

    assert_file 'config/initializers/dadata.rb' do |content|
      assert_match(/Конфигурация клиента DaData API/, content)
      assert_match(/Этот инициализатор использует Rails credentials/, content)
      assert_match(/API-ключи хранятся в файле/, content)
      assert_match(/rails credentials:edit/, content)
    end
  end

  test 'generator handles optional secret key in credentials-based initializer' do
    run_generator ['--use-credentials']

    assert_file 'config/initializers/dadata.rb' do |content|
      assert_match(/config\.secret_key = credentials\.secret_key if credentials\.respond_to\?\(:secret_key\)/, content)
    end
  end

  test 'generator adds proper error handling in credentials-based initializer' do
    run_generator ['--use-credentials']

    assert_file 'config/initializers/dadata.rb' do |content|
      assert_match(/if credentials\.nil\?/, content)
      assert_match(/raise KeyError, 'Секция dadata не найдена в credentials/, content)
      assert_match(/if config\.api_key\.nil\?/, content)
      assert_match(/raise KeyError, 'API-ключ DaData не найден в credentials/, content)
    end
  end

  test 'generator creates initializer with proper configuration structure' do
    run_generator ['--no-use-credentials']

    assert_file 'config/initializers/dadata.rb' do |content|
      assert_match(/# frozen_string_literal: true/, content)
      assert_match(/Dadata\.configure do \|config\|/, content)
      assert_match(/end/, content)
    end
  end
end
