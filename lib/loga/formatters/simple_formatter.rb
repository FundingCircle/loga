module Loga
  module Formatters
    class SimpleFormatter < Logger::Formatter
      include TaggedLogging::Formatter

      FORMAT = "%s, [%s #%d]%s %s\n".freeze

      def call(severity, time, _progname, object)
        FORMAT % [
          severity[0..0],
          time.iso8601(6),
          Process.pid,
          tags,
          compute_message(object),
        ]
      end

      private

      def compute_message(object)
        case object
        when Loga::Event
          compute_event_message(object)
        else
          msg2str(object)
        end
      end

      def compute_event_message(event)
        components = [event.message]

        %i[type data exception].each do |attr|
          components.push "#{attr}=#{event.public_send(attr)}" if event.public_send(attr)
        end

        components.join(' ')
      end

      def tags
        current_tags.empty? ? '' : "[#{current_tags.join(' ')}]"
      end
    end
  end
end
