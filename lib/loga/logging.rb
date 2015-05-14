require 'logger'
require 'socket'

module Loga
  module Logging
    def self.initialize_logger
      @logger           = Logger.new(Loga.configuration.device)
      @logger.formatter = GELFFormatter.new(
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
