require 'sidekiq/job_logger'

module Loga
  module Sidekiq7
    class JobLogger < ::Sidekiq::JobLogger
      EVENT_TYPE = 'sidekiq'.freeze

      def call(item, _queue)
        start = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)

        yield

        ::Sidekiq::Context.add(:elapsed, elapsed(start))

        loga_log(message: "#{item['class']} with jid: '#{item['jid']}' done", item: item)
      rescue Exception => e # rubocop:disable Lint/RescueException
        ::Sidekiq::Context.add(:elapsed, elapsed(start))

        loga_log(
          message: "#{item['class']} with jid: '#{item['jid']}' fail", item: item,
          exception: e
        )

        raise
      end

      private

      def loga_log(message:, item:, exception: nil)
        data = {
          'created_at'  => item['created_at'],
          'enqueued_at' => item['enqueued_at'],
          'jid'         => item['jid'],
          'queue'       => item['queue'],
          'retry'       => item['retry'],
          'params'      => item['args'],
          'class'       => item['class'],
        }

        data['exception'] = exception if exception

        event = Event.new(type: EVENT_TYPE, message: message, data: data)

        if exception
          @logger.warn(event)
        else
          @logger.info(event)
        end
      end
    end
  end
end
