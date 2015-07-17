module Loga
  class Configuration
    attr_accessor :service_name,
                  :service_version,
                  :device,
                  :filter_parameters,
                  :level,
                  :host

    attr_reader :logger

    def initialize(opts = {})
      defaults = {
        host:  Socket.gethostname,
        level: Logger::INFO,
        device: STDOUT,
        filter_parameters: [],
      }

      options = defaults.merge(opts)

      @host              = options[:host]
      @device            = options[:device]
      @level             = options[:level]
      @filter_parameters = options[:filter_parameters]
    end

    def initialize!
      @service_name.to_s.strip!
      @service_version.to_s.strip!

      @logger           = ActiveSupport::TaggedLogging.new(Logger.new(@device))
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
