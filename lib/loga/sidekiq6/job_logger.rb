require 'sidekiq/job_logger'

module Loga
  module Sidekiq6
    class JobLogger < ::Sidekiq::JobLogger
      EVENT_TYPE = 'sidekiq'.freeze

      def call(item, _queue)
        start = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)

        yield

        with_elapsed_time_context(start) do
          loga_log(
            message: "#{item['class']} with jid: '#{item['jid']}' done", item: item,
          )
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
        with_elapsed_time_context(start) do
          loga_log(
            message: "#{item['class']} with jid: '#{item['jid']}' fail", item: item,
            exception: e
          )
        end

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

        @logger.info(Event.new(type: EVENT_TYPE, message: message, data: data))
      end
    end
  end
end
