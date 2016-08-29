require 'active_support/core_ext/object/blank'
require 'active_support/version'
require 'loga/formatters/gelf_formatter'
require 'loga/formatters/simple_formatter'
require 'loga/service_version_strategies'
require 'logger'
require 'socket'

module Loga
  class Configuration
    FRAMEWORK_EXCEPTIONS = %w(
      ActionController::RoutingError
      ActiveRecord::RecordNotFound
      Sinatra::NotFound
    ).freeze

    attr_accessor :device, :filter_exceptions, :filter_parameters, :format,
                  :host, :level, :service_name, :service_version, :sync, :tags
    attr_reader :logger

    def initialize(user_options = {}, framework_options = {})
      options = default_options.merge(framework_options)
                               .merge(environment_options)
                               .merge(user_options)

      self.device            = options[:device]
      self.filter_exceptions = options[:filter_exceptions]
      self.filter_parameters = options[:filter_parameters]
      self.format            = options[:format]
      self.host              = options[:host]
      self.level             = options[:level]
      self.service_name      = options[:service_name]
      self.service_version   = options[:service_version] || ServiceVersionStrategies.call
      self.sync              = options[:sync]
      self.tags              = options[:tags]

      validate

      @logger = initialize_logger
    end

    def format=(name)
      @format = name.to_s.to_sym
    end

    def service_name=(name)
      @service_name = name.to_s.strip
    end

    def structured?
      format == :gelf
    end

    private

    def validate
      raise ConfigurationError, 'Service name cannot be blank' if service_name.blank?
      raise ConfigurationError, 'Device cannot be blank' if device.blank?
    end

    def default_options
      {
        device:            STDOUT,
        filter_exceptions: FRAMEWORK_EXCEPTIONS,
        filter_parameters: [],
        format:            :simple,
        host:              hostname,
        level:             :info,
        sync:              true,
        tags:              [],
      }
    end

    def environment_options
      { format: ENV['LOGA_FORMAT'].presence }.reject { |_, v| v.nil? }
    end

    def initialize_logger
      device.sync      = sync
      logger           = ContextLogger.new(device)
      logger.formatter = assign_formatter
      logger.level     = constantized_log_level
      TaggedLogging.new(logger)
    end

    def constantized_log_level
      ContextLogger.const_get(level.to_s.upcase)
    end

    def hostname
      Socket.gethostname
    rescue SystemCallError
      'unknown.host'
    end

    def assign_formatter
      if format == :gelf
        Formatters::GELFFormatter.new(
          service_name:    service_name,
          service_version: service_version,
          host:            host,
        )
      else
        Formatters::SimpleFormatter.new
      end
    end
  end
end
