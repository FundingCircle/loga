require 'active_support/core_ext/object/blank'
require 'logger'
require 'socket'

module Loga
  class Configuration
    ServiceNameMissingError = Class.new(StandardError)

    DEFAULT_KEYS = %i(
      device
      enabled
      filter_parameters
      formatter
      host
      level
      service_name
      service_version
      silence_rails_rack_logger
      sync
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

      raise ServiceNameMissingError if service_name.blank?
    end

    def initialize!
      @service_version = compute_service_version
      initialize_logger
    end

    def service_name=(name)
      @service_name = name.to_s.strip
    end

    private

    def default_options
      {
        device:                    STDOUT,
        enabled:                   true,
        filter_parameters:         [],
        host:                      gethostname,
        level:                     :info,
        service_version:           :git,
        silence_rails_rack_logger: true,
        sync:                      true,
      }
    end

    def environment_options
      ENV['LOGA_FORMATTER'].blank? ? {} : { formatter: ENV['LOGA_FORMATTER'] }
    end

    def compute_service_version
      RevisionStrategy.call(service_version)
    end

    def initialize_logger
      device.sync = sync

      logger           = Logger.new(device)
      logger.formatter = Formatter.new(
        service_name:    service_name,
        service_version: service_version,
        host:            host,
      )
      logger.level     = constantized_log_level
    rescue
      logger           = Logger.new(STDERR)
      logger.level     = Logger::ERROR
      logger.error 'Loga could not be initialized'
    ensure
      @logger          = TaggedLogging.new(logger)
    end

    def constantized_log_level
      Logger.const_get(level.to_s.upcase)
    end

    def gethostname
      Socket.gethostname
    rescue Exception
      'unknown.host'
    end
  end
end
