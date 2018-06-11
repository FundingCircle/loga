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

module Loga
  ConfigurationError = Class.new(StandardError)

  def self.configuration
    unless @configuration
      raise ConfigurationError,
            'Loga has not been configured. Configure with Loga.configure(options)'
    end

    @configuration
  end

  def self.configure(options, framework_options = {})
    raise ConfigurationError, 'Loga has already been configured' if @configuration

    @configuration ||= Configuration.new(options, framework_options)

    Loga::Sidekiq.configure_logging
  end

  def self.logger
    configuration.logger
  end

  def self.reset
    @configuration = nil
  end
end
