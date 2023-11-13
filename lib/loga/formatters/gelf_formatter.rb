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
        event = message.is_a?(Loga::Event) ? message : Loga::Event.new(message: message)

        event.timestamp ||= time
        # Overwrite sidekiq_context data anything manually specified
        event.data = sidekiq_context.merge!(event.data || {})
        event.data.tap do |hash|
          hash.merge! compute_exception(event.exception)
          hash.merge! compute_type(event.type)
          # Overwrite hash with Loga's additional fields
          hash.merge! loga_additional_fields
          hash.merge! open_telemetry_fields
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

      def open_telemetry_fields
        return {} unless defined?(::OpenTelemetry::Trace)

        span = ::OpenTelemetry::Trace.current_span

        {
          trace_id: span.context.hex_trace_id,
          span_id: span.context.hex_span_id,
        }
      end

      def sidekiq_context
        return {} unless defined?(::Sidekiq::Context)

        c = ::Sidekiq::Context.current

        # The context usually holds :class and :jid. :elapsed is added when the job ends
        data = c.dup
        if data.key?(:elapsed)
          data[:duration] = data[:elapsed].to_f
          data.delete(:elapsed)
        end
        data
      end
    end
  end
end
