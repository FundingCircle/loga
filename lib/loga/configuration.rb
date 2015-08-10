require 'logger'
require 'socket'
require 'active_support'
require 'active_support/core_ext/object/blank'

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
      @service_version   = :git

      # Rails specific configuration
      @enable            = true
      @silence_rails_rack_logger = true
    end

    def initialize!
      @service_name.to_s.strip!
      @service_version = compute_service_version

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

    class GitRevisionStrategy
      DEFAULT_REVISION = 'unknown.sha'.freeze

      def self.call
        revision = fetch_revision   if binary_available?
        revision = DEFAULT_REVISION if revision.blank?
        revision
      end

      def self.binary_available?
        system 'which -s git'
      end

      def self.fetch_revision
        `git rev-parse HEAD`.strip
      end
    end

    def compute_service_version
      service_version == :git ? GitRevisionStrategy.call : service_version.strip
    end

    def gethostname
      Socket.gethostname
    rescue Exception
      'unknown.host'
    end
  end
end
