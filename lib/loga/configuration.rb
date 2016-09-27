require 'logger'
require 'socket'

module Loga
  class Configuration
    ServiceNameMissingError = Class.new(StandardError)

    DEFAULTS = {
      device:            -> { STDOUT },
      filter_parameters: -> { [] },
      formatter:         -> { ENV['LOGA_FORMATTER'] },
      host: lambda do
        begin
          Socket.gethostname
        rescue Exception
          'unknown.host'
        end
      end,
      level:             -> { :info },
      service_name:      -> { raise ServiceNameMissingError },
      service_version:   -> { :git },
      sync:              -> { true },
      enabled:           -> { true },
      silence_rails_rack_logger: -> { true },
    }.freeze

    private_constant :DEFAULTS
    attr_accessor(*DEFAULTS.keys)
    attr_reader :logger

    def initialize(options = {})
      DEFAULTS.each do |attribute, value|
        public_send("#{attribute}=", options.fetch(attribute) { value.call })
      end
    end

    def initialize!
      @service_version = compute_service_version
      initialize_logger
    end

    def service_name=(name)
      @service_name = name.to_s.strip
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
  end
end
