require 'logger'
require 'json'

module Loga
  module Formatters
    class GELFFormatter < Logger::Formatter
      include TaggedLogging::Formatter

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
        event = build_event(time, message)
        payload = format_additional_fields(event.data)

        payload[:short_message] = event.message
        payload[:timestamp]     = compute_timestamp(event.timestamp)
        payload[:host]          = @host
        payload[:level]         = compute_level(severity)
        payload[:version]       = GELF_VERSION

        "#{payload.to_json}\n"
      end

      private

      def build_event(time, message)
        event = case message
                when Loga::Event
                  message
                else
                  Loga::Event.new(message: message)
                end

        event.timestamp ||= time
        event.data ||= {}
        event.data.tap do |hash|
          hash.merge! compute_exception(event.exception)
          hash.merge! compute_type(event.type)
          # Overwrite hash with Loga's additional fields
          hash.merge! loga_additional_fields
        end
        event
      end

      def compute_timestamp(timestamp)
        (timestamp.to_f * 1000).floor / 1000.0
      end

      def compute_level(severity)
        SYSLOG_LEVEL_MAPPING[severity]
      end

      def format_additional_fields(fields)
        fields.each_with_object({}) do |(main_key, values), hash|
          if values.is_a?(Hash)
            values.each do |sub_key, sub_values|
              hash["_#{main_key}.#{sub_key}"] = sub_values
            end
          else
            hash["_#{main_key}"] = values
          end
        end
      end

      def compute_exception(exception)
        return {} unless exception
        {
          exception: {
            klass:     exception.class.to_s,
            message:   exception.message,
            backtrace: exception.backtrace.first(10).join("\n"),
          },
        }
      end

      def compute_type(type)
        type ? { type: type } : {}
      end

      def loga_additional_fields
        {
          service: {
            name:    @service_name,
            version: @service_version,
          },
          tags: current_tags.join(' '),
        }
      end
    end
  end
end
