module ServiceLogger
  module Sidekiq
    class ServerLogger
      def call(_worker, item, _queue)
        started_at = Time.now

        begin
          yield
        ensure
          data = {
            retry:       item['retry'],
            klass:       item['class'],
            jid:         item['jid'],
            params:      item['args'],
            enqueued_at: Time.at(item['enqueued_at']).utc.iso8601(3),
            queue:       item['queue'],
            retry_count: item['retry_count'],
            duration:    ((Time.now - started_at) * 1000).round,
          }

          data[:failed_at]  = Time.at(item['failed_at']).utc.iso8601(3)  if item['failed_at']
          data[:retried_at] = Time.at(item['retried_at']).utc.iso8601(3) if item['retried_at']

          logger.info(
            type: 'job_processed',
            data: data,
            timestamp: started_at,
          )
        end
      end

      def logger
        ServiceLogger.logger
      end
    end
  end
end
