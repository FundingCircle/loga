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

module Loga
  ConfigurationError = Class.new(StandardError)

  def self.configuration
    if @configuration.nil?
      raise ConfigurationError,
            'Loga has not been configured. Configure with Loga.configure(options)'
    end
    @configuration
  end

  def self.configure(options, framework_options = {})
    unless @configuration.nil?
      raise ConfigurationError, 'Loga has already been configured'
    end
    @configuration ||= Configuration.new(options, framework_options)
  end

  def self.logger
    configuration.logger
  end

  def self.reset
    @configuration = nil
  end
end
