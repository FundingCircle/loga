module Loga
  module Sidekiq
    # The approach of using a custom job logger in sidekiq was introduced
    # in v5.0: https://github.com/mperham/sidekiq/pull/3235
    # This job logger does not support logging for Sidekiq versions
    # that are before 5.0
    class JobLogger
      include Loga::Utilities

      EVENT_TYPE = 'sidekiq'.freeze

      attr_reader :started_at, :data

      def initialize
        @started_at = Time.now
        @data = {}
      end

      def call(item, _queue)
        yield
      rescue Exception => ex # rubocop:disable Lint/RescueException
        data['exception'] = ex

        raise
      ensure
        assign_data(item)
        send_message
      end

      private

      def assign_data(item)
        data['created_at']  = item['created_at']
        data['enqueued_at'] = item['enqueued_at']
        data['jid']         = item['jid']
        data['queue']       = item['queue']
        data['retry']       = item['retry']
        data['params']      = item['args']
        data['class']       = item['class']
        data['duration']    = duration_in_ms(started_at)
      end

      def short_message
        "#{data['class']} with jid: '#{data['jid']}' executed in #{data['duration']}ms"
      end

      def send_message
        event = Event.new(data: data, message: short_message, type: EVENT_TYPE)

        logger.public_send(compute_level, event)
      end

      def compute_level
        data.key?('exception') ? :warn : :info
      end

      def logger
        Loga.logger
      end
    end
  end
end