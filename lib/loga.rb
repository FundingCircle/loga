require 'loga/version'
require 'loga/utilities'
require 'loga/gelf_formatter'
require 'loga/gelf_udp_log_device'
require 'loga/logging'
require 'loga/rack/logger'
require 'loga/sidekiq/client_logger'
require 'loga/sidekiq/server_logger'

module Loga
  Configuration = Struct.new(
    :service_name,
    :service_version,
    :device,
    :filter_parameters,
  )

  def self.configuration
    @configuration ||= Configuration.new(
      '',
      '',
      STDOUT,
      [],
    )
  end

  def self.configure
    yield configuration
  end

  def self.logger
    Logging.logger
  end
end
