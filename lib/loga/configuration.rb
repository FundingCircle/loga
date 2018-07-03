require 'active_support/core_ext/object/blank'
require 'active_support/version'
require 'loga/formatters/gelf_formatter'
require 'loga/formatters/simple_formatter'
require 'loga/service_version_strategies'
require 'logger'
require 'socket'

module Loga
  class Configuration
    FRAMEWORK_EXCEPTIONS = %w[
      ActionController::RoutingError
      ActiveRecord::RecordNotFound
      Sinatra::NotFound
    ].freeze

    attr_reader :device, :filter_exceptions, :filter_parameters, :format, :hide_pii,
                :host, :level, :service_name, :service_version, :sync, :tags

    def initialize(user_options = {}, framework_options = {})
      options = default_options.merge(framework_options)
                               .merge(environment_options)
                               .merge(user_options)

      @device            = options[:device]
      @filter_exceptions = options[:filter_exceptions]
      @filter_parameters = options[:filter_parameters]
      @format            = options[:format].to_s.to_sym
      @hide_pii          = options[:hide_pii]
      @host              = options[:host]
      @level             = options[:level]
      @service_name      = options[:service_name].to_s.strip
      @service_version   = options[:service_version] || ServiceVersionStrategies.call
      @sync              = options[:sync]
      @tags              = options[:tags]

      validate
    end

    def structured?
      format == :gelf
    end

    def logger
      @logger ||= begin
        device.sync          = sync
        new_logger           = Logger.new(device)
        new_logger.formatter = assign_formatter
        new_logger.level     = constantized_log_level

        TaggedLogging.new(new_logger)
      end
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
        hide_pii:          true,
      }
    end

    def environment_options
      { format: ENV['LOGA_FORMAT'].presence }.reject { |_, v| v.nil? }
    end

    def constantized_log_level
      Logger.const_get(level.to_s.upcase)
    end

    def hostname
      Socket.gethostname
    rescue SystemCallError
      'unknown.host'
    end

    def assign_formatter
      return Formatters::SimpleFormatter.new if format != :gelf

      Formatters::GELFFormatter.new(
        service_name:    service_name,
        service_version: service_version,
        host:            host,
      )
    end
  end
end
