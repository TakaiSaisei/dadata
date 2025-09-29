# frozen_string_literal: true

require 'rails/generators'

module Dadata
  module Generators
    # Rails generator for DaData API configuration
    class InitializerGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      class_option :api_key,
                   type:    :string,
                   default: 'DADATA_API_KEY',
                   desc:    'Your DaData API key'

      class_option :secret_key,
                   type:    :string,
                   default: 'DADATA_SECRET_KEY',
                   desc:    'Your DaData secret key'

      class_option :use_credentials,
                   type:    :boolean,
                   default: true,
                   desc:    'Store API keys in Rails credentials'

      class_option :timeout,
                   type:    :numeric,
                   default: 3,
                   desc:    'API request timeout in seconds'

      class_option :suggestions_count,
                   type:    :numeric,
                   default: 10,
                   desc:    'Default number of suggestions to return'

      def create_initializer
        @api_key = options[:api_key]
        @secret_key = options[:secret_key]
        @timeout = options[:timeout]
        @suggestions_count = options[:suggestions_count]

        if options[:use_credentials]
          create_credentials
          template 'dadata_credentials.rb', 'config/initializers/dadata.rb'
        else
          template 'dadata.rb', 'config/initializers/dadata.rb'
        end
      end

      private

      def create_credentials
        return unless options[:use_credentials]

        # Skip if both keys are already in credentials
        credentials = Rails.application.credentials.dadata
        return if credentials&.api_key.present? && credentials&.secret_key.present?

        # Create or update credentials
        content = <<~YAML
          dadata:
            api_key: #{@api_key}
            secret_key: #{@secret_key}
        YAML

        # Create credentials directory if it doesn't exist
        FileUtils.mkdir_p(File.dirname(Rails.application.credentials.content_path))

        if File.exist?(Rails.application.credentials.content_path)
          # If credentials exist but don't have dadata config, append it
          current_content = File.read(Rails.application.credentials.content_path)
          if current_content.match?(/^dadata:/m)
            say_status :skip, 'credentials already contain DaData configuration', :yellow
          else
            File.write(Rails.application.credentials.content_path, "#{current_content}\n#{content}")
            say_status :update, 'config/credentials.yml.enc', :green
          end
        else
          # Create new credentials file
          File.write(Rails.application.credentials.content_path, content)
          say_status :create, 'config/credentials.yml.enc', :green
        end
      end
    end
  end
end
