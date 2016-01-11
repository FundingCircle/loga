require 'logger'
require 'socket'
require 'active_support'
require 'active_support/core_ext/object/blank'

module Loga
  class Configuration
    attr_accessor :service_name,
                  :service_version,
                  :device,
                  :sync,
                  :filter_parameters,
                  :level,
                  :host,
                  :enabled,
                  :silence_rails_rack_logger

    attr_reader :logger

    def initialize
      @host              = gethostname
      @device            = nil
      @sync              = true
      @level             = :info
      @filter_parameters = []
      @service_version   = :git

      # Rails specific configuration
      @enabled           = true
      @silence_rails_rack_logger = true
    end

    def initialize!
      @service_name.to_s.strip!
      @service_version = compute_service_version

      initialize_logger
    end

    def configure
      yield self
    end

    private

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
