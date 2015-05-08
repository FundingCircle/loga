require 'logger'

module ServiceLogger
  # Graylog Extended Log Format (GELF) Formatter v1.1
  # Specification https://www.graylog.org/resources/gelf-2/
  class GELFFormatter < Logger::Formatter
    include Utilities

    VERSION               = '1.1'.freeze
    SYSLOG_LEVELS_MAPPING = {
      'DEBUG'   => 7,
      'INFO'    => 6,
      'WARN'    => 4,
      'ERROR'   => 3,
      'FATAL'   => 2,
      'UNKNOWN' => 1,
    }.freeze

    def initialize(opts)
      @service_name    = opts.fetch(:service_name)
      @service_version = opts.fetch(:service_version)
      @host            = opts.fetch(:host)
    end

    def call(severity, time, _progname, message)
      event = {
        'version'          => VERSION,
        'host'             => @host,
        'short_message'    =>  message.fetch(:short_message),
        'full_message'     => '',
        'timestamp'        => unix_time_with_ms(message.fetch(:timestamp, time)),
        'level'            => severity_to_syslog_level(severity),
        '_event_type'      => message.fetch(:type, 'custom'),
        '_service.name'    => @service_name,
        '_service.version' => @service_version,
      }

      event.merge! extract_exception(message.delete(:exception))

      event.merge!(message.fetch(:data, {}))
      "#{JSON.dump(event)}\n"
    end

    def severity_to_syslog_level(severity)
      SYSLOG_LEVELS_MAPPING[severity]
    end

    private

    def extract_exception(e)
      return {} if e.nil?
      {
        '_exception.backtrace' => e.backtrace.join("\n"),
        '_exception.message'   => e.message,
        '_exception.klass'     => e.class.to_s,
      }
    end
  end
end
