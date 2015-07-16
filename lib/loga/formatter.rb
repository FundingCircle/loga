require 'logger'
require 'json'
require 'active_support/tagged_logging'

module Loga
  class Formatter < Logger::Formatter
    include ActiveSupport::TaggedLogging::Formatter
    GELF_VERSION = '1.1'.freeze
    SYSLOG_LEVEL_MAPPING = {
      'DEBUG'   => 7,
      'INFO'    => 6,
      'WARN'    => 4,
      'ERROR'   => 3,
      'FATAL'   => 2,
      'UNKNOWN' => 1,
    }.freeze
    DEFAULT_TYPE = 'default'.freeze

    def initialize(opts)
      @service_name    = opts.fetch(:service_name)
      @service_version = opts.fetch(:service_version)
      @host            = opts.fetch(:host)
    end

    def call(severity, time, _progname, message)
      event = compute_extra_fields(
        message_extra_fields(message).merge!(base_extra_fields),
      )

      event[:short_message] = compute_message(message)
      event[:timestamp]     = compute_timestamp(message, time)
      event[:host]          = @host
      event[:level]         = compute_level(severity)
      event[:version]       = GELF_VERSION

      "#{event.to_json}\n"
    end

    private

    def compute_message(message)
      (message.is_a?(Hash) ? message[:message] : message).to_s
    end

    def compute_timestamp(message, time)
      timestamp = if message.is_a?(Hash) && message[:timestamp].is_a?(Time)
                    message[:timestamp]
                  else
                    time
                  end
      (timestamp.to_f * 1000).floor / 1000.0
    end

    def compute_level(severity)
      SYSLOG_LEVEL_MAPPING[severity]
    end

    def compute_extra_fields(fields)
      fields.each_with_object({}) do |(main_key, values), hash|
        if values.is_a?(Hash)
          values.each do |sub_key, sub_values|
            hash["_#{main_key}.#{sub_key}"] = sub_values
          end
        else
          hash["_#{main_key}"] = values
        end
        hash
      end
    end

    def message_extra_fields(message)
      return {} unless message.is_a?(Hash)
      event        = message[:event] || {}
      event[:type] = message[:type] || DEFAULT_TYPE

      exception = message[:exception]
      if exception
        event[:exception] = {
          klass:     exception.class.to_s,
          message:   exception.message,
          backtrace: exception.backtrace.first(10).join("\n"),
        }
      end
      event
    end

    def base_extra_fields
      {
        service: {
          name:    @service_name,
          version: @service_version,
        },
        tags: current_tags,
      }
    end
  end
end
