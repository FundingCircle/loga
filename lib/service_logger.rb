require 'service_logger/version'
require 'service_logger/utilities'
require 'service_logger/gelf_formatter'
require 'service_logger/gelf_udp_log_device'
require 'service_logger/logging'
require 'service_logger/rack/logger'
require 'service_logger/sidekiq/client_logger'
require 'service_logger/sidekiq/server_logger'

module ServiceLogger
  Configuration = Struct.new(
    :service_name,
    :service_version,
    :device,
  )

  def self.configuration
    @configuration ||= Configuration.new(
      service_name: '',
      service_version: '',
      device: STDOUT,
    )
  end

  def self.configure
    yield configuration
  end

  def self.logger
    Logging.logger
  end
end
