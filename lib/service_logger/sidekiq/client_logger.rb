module ServiceLogger
  module Sidekiq
    class ClientLogger
      include Utilities

      def call(_worker, item, _queue, _redis_pool)
        started_at = Time.now
        exception  = nil

        begin
          yield
        rescue Exception => e
          exception = e
          raise e
        ensure
          data = {}
          data['_job.retry']       = item['retry']
          data['_job.klass']       = item['class']
          data['_job.jid']         = item['jid']
          data['_job.params']      = item['args']
          data['_job.enqueued_at'] = extract_unix_timestamp(item['enqueued_at'])
          data['_job.queue']       = item['queue']
          data['_job.retry_count'] = item['retry_count']
          data['_job.duration']    = duration_in_ms(started_at, Time.now)
          data['_job.failed_at']   = extract_unix_timestamp(item['failed_at'])
          data['_job.retried_at']  = extract_unix_timestamp(item['retried_at'])

          logger.public_send(exception ? :error : :info,
                             type:          'job_enqueued',
                             short_message: short_message(data),
                             data:          data,
                             timestamp:     started_at,
                             exception:     exception,
                            )
        end
      end

      def short_message(data)
        format('%s Enqueued',
               data['_job.klass'],
              )
      end

      def extract_unix_timestamp(timestamp)
        return if timestamp.nil?
        unix_time_with_ms Time.at(timestamp)
      end

      def logger
        ServiceLogger.logger
      end
    end
  end
end
