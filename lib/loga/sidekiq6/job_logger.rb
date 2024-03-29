require 'sidekiq/job_logger'

module Loga
  module Sidekiq6
    class JobLogger < ::Sidekiq::JobLogger
      EVENT_TYPE = 'sidekiq'.freeze

      def call(item, _queue)
        start = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)

        yield

        ::Sidekiq::Context.current[:elapsed] = elapsed(start)

        loga_log(message: "#{item['class']} with jid: '#{item['jid']}' done", item: item)
      rescue Exception => e # rubocop:disable Lint/RescueException
        ::Sidekiq::Context.current[:elapsed] = elapsed(start)

        loga_log(
          message: "#{item['class']} with jid: '#{item['jid']}' fail", item: item,
          exception: e
        )

        raise
      end

      def prepare(job_hash, &block)
        super
      ensure
        # For sidekiq version < 6.4
        Thread.current[:sidekiq_context] = nil
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
        if exception
          data['exception'] = exception
          @logger.warn(Event.new(type: EVENT_TYPE, message: message, data: data))
        else
          @logger.info(Event.new(type: EVENT_TYPE, message: message, data: data))
        end
      end
    end
  end
end
