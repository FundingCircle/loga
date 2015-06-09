require 'loga/version'
require 'loga/configuration'
require 'loga/utilities'
require 'loga/gelf_formatter'
require 'loga/logstash_formatter.rb'
require 'loga/gelf_udp_log_device'
require 'loga/logging'
require 'loga/rack/logger'
require 'loga/sidekiq/client_logger'
require 'loga/sidekiq/server_logger'

module Loga
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end

  def self.initialize!
    configuration.initialize!
  end

  def self.logger
    configuration.logger
  end

  def self.reset
    @configuration = nil
  end
end
