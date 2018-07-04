require 'loga/version'
require 'loga/tagged_logging'
require 'loga/configuration'
require 'loga/utilities'
require 'loga/event'
require 'loga/parameter_filter'
require 'loga/rack/logger'
require 'loga/rack/request'
require 'loga/rack/request_id'
require 'loga/railtie' if defined?(Rails)
require 'loga/sidekiq'
require 'loga/context_manager'

module Loga
  ConfigurationError = Class.new(StandardError)

  class << self
    def configuration
      unless @configuration
        raise ConfigurationError,
              'Loga has not been configured. Configure with Loga.configure(options)'
      end

      @configuration
    end

    def configure(options, framework_options = {})
      raise ConfigurationError, 'Loga has already been configured' if @configuration

      @configuration ||= Configuration.new(options, framework_options)

      Loga::Sidekiq.configure_logging
    end

    def logger
      configuration.logger
    end

    def reset
      @configuration = nil
    end

    def attach_context(payload)
      current_context.attach_context(payload)
    end

    def clear_context
      current_context.clear
    end

    def retrieve_context
      current_context.retrieve_context
    end

    private

    def current_context
      ContextManager.current
    end
  end
end
