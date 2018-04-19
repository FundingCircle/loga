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
        message = "#{mailer}: Sent mail to #{recipients} in (#{duration}ms)"

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

        loga_event = Event.new(
          data: { mailer: mailer, unique_id: unique_id },
          message: "Received mail #{from} in (#{event.duration.round(1)}ms)",
          type: 'action_mailer',
        )

        logger.info(loga_event)
      end

      def logger
        Loga.logger
      end
    end
  end
end
