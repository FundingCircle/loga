require 'logger'
require 'socket'
require 'json'

module ServiceLogger
  module Logging
    def self.initialize_logger
      @logger           = Logger.new(ServiceLogger.configuration.log_target)
      @logger.formatter = GELFFormatter.new(
        service_name:    ServiceLogger.configuration.service_name,
        service_version: ServiceLogger.configuration.service_version,
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
