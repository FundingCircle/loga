module Loga
  module LogSubscribers
    # Loga::LogSubscribers::ActionMailer tracks the three
    # mailing events: 'process', 'deliver' and 'receive', and
    # builds a loga event instance for each particular invocation.
    class ActionMailer < ActiveSupport::LogSubscriber
      def deliver(event)
        mailer     = event.payload[:mailer]
        recipients = event.payload[:to].join(',')
        unique_id  = event.payload[:unique_id]
        duration   = event.duration.round(1)
        message    = ''.tap do |string|
          string << "#{mailer}: Sent mail"
          string << " to #{recipients}" unless hide_pii?
          string << " in (#{duration}ms)"
        end

        loga_event = Event.new(
          data: { mailer: mailer, unique_id: unique_id },
          message: message,
          type: 'action_mailer',
        )

        logger.info(loga_event)
      end

      def process(event)
        mailer = event.payload[:mailer]
        action = event.payload[:action]
        unique_id = event.payload[:unique_id]
        duration  = event.duration.round(1)

        message = "#{mailer}##{action}: Processed outbound mail in (#{duration}ms)"

        loga_event = Event.new(
          data: { mailer: mailer, unique_id: unique_id, action: action },
          message: message,
          type: 'action_mailer',
        )

        logger.debug(loga_event)
      end

      def receive(event)
        from      = event.payload[:from]
        mailer    = event.payload[:mailer]
        unique_id = event.payload[:unique_id]
        message   = ''.tap do |string|
          string << 'Received mail'
          string << " from #{from}" unless hide_pii?
          string << " in (#{event.duration.round(1)}ms)"
        end

        loga_event = Event.new(
          data: { mailer: mailer, unique_id: unique_id },
          message: message,
          type: 'action_mailer',
        )

        logger.info(loga_event)
      end

      def logger
        Loga.logger
      end

      def hide_pii?
        Loga.configuration.hide_pii
      end
    end
  end
end
