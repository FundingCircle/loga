require 'loga/version'
require 'loga/tagged_logging'
require 'loga/configuration'
require 'loga/utilities'
require 'loga/formatter'
require 'loga/rack/logger'
require 'loga/rack/request'
require 'loga/rack/request_id'

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
