require 'logger'
require 'socket'

module Loga
  class Configuration
    attr_accessor :service_name,
                  :service_version,
                  :device,
                  :filter_parameters,
                  :level,
                  :host,
                  :enable,
                  :silence_rails_rack_logger

    attr_reader :logger

    def initialize
      @host              = gethostname
      @device            = STDOUT
      @level             = Logger::INFO
      @filter_parameters = []

      # Rails specific configuration
      @enable            = true
      @silence_rails_rack_logger = true
    end

    def initialize!
      @service_name.to_s.strip!
      @service_version.to_s.strip!

      @logger           = TaggedLogging.new(Logger.new(@device))
      @logger.level     = @level
      @logger.formatter = Formatter.new(
        service_name:    @service_name,
        service_version: @service_version,
        host:            @host,
      )
      @logger
    end

    def configure
      yield self
    end

    private

    def gethostname
      Socket.gethostname
    rescue Exception
      'unknown.host'
    end
  end
end
