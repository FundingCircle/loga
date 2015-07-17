require 'logger'
require 'json'
require 'active_support/tagged_logging'

module Loga
  class Formatter < Logger::Formatter
    include ActiveSupport::TaggedLogging::Formatter

    DEFAULT_TYPE = 'default'.freeze

    def initialize(opts)
      @service_name    = opts.fetch(:service_name)
      @service_version = opts.fetch(:service_version)
      @host            = opts.fetch(:host)
    end

    def call(severity, time, _progname, message)
      event = build_event(message, severity, time)
      "#{event.to_json}\n"
    end

    private

    def build_event(message, severity, time)
      event = case message
              when Hash
                build_event_with_hash(message, time)
              else
                LogStash::Event.new(message: message, '@timestamp' => time)
              end

      event[:service] = {
        name:    @service_name,
        version: @service_version,
      }
      event[:host]     = @host
      event[:severity] = severity

      event.tags = current_tags
      # In case Time#to_json has been overridden
      event.timestamp = event.timestamp.utc.iso8601(3) if event.timestamp.is_a?(Time)

      event
    end

    def build_event_with_hash(message, time)
      event = LogStash::Event.new

      exception = message[:exception]
      if exception
        event[:exception] = {
          klass:     exception.class.to_s,
          message:   exception.message,
          backtrace: exception.backtrace,
        }
      end

      event[:event]   = message[:event] || {}
      event[:type]    = message[:type] || DEFAULT_TYPE
      event[:message] = message[:message]
      event.timestamp = message[:timestamp] || time

      event
    end
  end
end
