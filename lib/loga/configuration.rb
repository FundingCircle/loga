require 'active_support/core_ext/object/blank'
require 'active_support/version'
require 'logger'
require 'socket'

module Loga
  # rubocop:disable Metrics/ClassLength
  class Configuration
    DEFAULT_KEYS = %i(
      device
      filter_exceptions
      filter_parameters
      format
      host
      level
      service_name
      service_version
      sync
      tags
    ).freeze

    FRAMEWORK_EXCEPTIONS = %w(
      ActionController::RoutingError
      ActiveRecord::RecordNotFound
      Sinatra::NotFound
    ).freeze

    attr_accessor(*DEFAULT_KEYS)
    attr_reader :logger
    private_constant :DEFAULT_KEYS

    def initialize(user_options = {}, framework_options = {})
      options = default_options.merge(framework_options)
                               .merge(environment_options)
                               .merge(user_options)

      DEFAULT_KEYS.each do |attribute|
        public_send("#{attribute}=", options[attribute])
      end

      raise ConfigurationError, 'Service name cannot be blank' if service_name.blank?
      raise ConfigurationError, 'Device cannot be blank' if device.blank?

      # TODO: @service_version = compute_service_version
      initialize_logger
    end

    def format=(name)
      @format = name.to_s.to_sym
    end

    def service_name=(name)
      @service_name = name.to_s.strip
    end

    def service_version=(name)
      @service_version = name.to_s.strip
    end

    def structured?
      format == :gelf
    end

    private

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
      { format: ENV['LOGA_FORMAT'].presence }.delete_if { |_, v| v.nil? }
    end

    def compute
      _service_version
      RevisionStrategy.call(service_version)
    end

    def initialize_logger
      device.sync = sync

      logger           = Logger.new(device)
      logger.formatter = assign_formatter
      logger.level     = constantized_log_level
      @logger          = TaggedLogging.new(logger)
    end

    def constantized_log_level
      Logger.const_get(level.to_s.upcase)
    end

    # rubocop:disable Lint/RescueException
    def hostname
      Socket.gethostname
    rescue Exception
      'unknown.host'
    end
    # rubocop:enable Lint/RescueException

    def assign_formatter
      if format == :gelf
        Formatter.new(
          service_name:    service_name,
          service_version: service_version,
          host:            host,
        )
      else
        active_support_simple_formatter
      end
    end

    def active_support_simple_formatter
      case ActiveSupport::VERSION::MAJOR
      when 3
        require 'active_support/core_ext/logger'
        Logger::SimpleFormatter.new
      when 4..5
        require 'active_support/logger'
        ActiveSupport::Logger::SimpleFormatter.new
      else
        raise Loga::ConfigurationError,
              "ActiveSupport #{ActiveSupport::VERSION::MAJOR} is unsupported"
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
