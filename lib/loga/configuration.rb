require 'logstash-logger'

module Loga
  class Configuration
    attr_accessor :service_name,
                  :service_version,
                  :devices,
                  :filter_parameters,
                  :level,
                  :host

    attr_reader :logger

    def initialize(opts = {})
      defaults = {
        host:  Socket.gethostname,
        level: Logger::INFO,
        devices: [{ type: :stdout }],
        filter_parameters: [],
      }

      options = defaults.merge(opts)

      @host              = options[:host]
      @devices           = options[:devices]
      @level             = options[:level]
      @filter_parameters = options[:filter_parameters]
    end

    def initialize!
      @service_name.to_s.strip!
      @service_version.to_s.strip!

      @logger           = LogStashLogger.new(@devices)
      @logger.level     = @level
      @logger.formatter = Formatter.new(
        service_name:    @service_name,
        service_version: @service_version,
        host:            @host,
      )
      @logger
    end
  end
end
