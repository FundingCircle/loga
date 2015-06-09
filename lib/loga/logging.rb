require 'logger'
require 'socket'

module Loga
  module Logging
    def self.initialize_logger
      @logger           = LogStashLogger.new([
        { type: :stdout },
        # { type: :tcp, host: 'docker.local', port: 3333 },
      ])
      @logger.formatter = LogStashFormatter.new(
        service_name:    Loga.configuration.service_name,
        service_version: Loga.configuration.service_version,
        host:            Socket.gethostname,
      )
      @logger.level     = Logger::INFO
      @logger
    end

    def self.logger
      defined?(@logger) ? @logger : initialize_logger
    end

    def self.reset
      remove_instance_variable(:@logger) if defined?(@logger)
    end
  end
end
