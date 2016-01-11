require 'loga/version'
require 'loga/tagged_logging'
require 'loga/configuration'
require 'loga/utilities'
require 'loga/event'
require 'loga/formatter'
require 'loga/parameter_filter'
require 'loga/revision_strategy'
require 'loga/rack/logger'
require 'loga/rack/request'
require 'loga/rack/request_id'
require 'loga/railtie' if defined?(Rails)

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
