module ServiceLogger
  module Sidekiq
    class ClientLogger
      include Utilities

      def call(_worker, item, _queue, _redis_pool)
        started_at = Time.now
        severity   = :info
        data       = {}

        begin
          yield
        rescue Exception => e
          severity = :error
          data['_exception.backtrace'] = e.backtrace.join("\n")
          data['_exception.message']   = e.message
          data['_exception.klass']     = e.class.to_s
          raise e
        ensure
          data['_job.retry']       = item['retry']
          data['_job.klass']       = item['class']
          data['_job.jid']         = item['jid']
          data['_job.params']      = item['args']
          data['_job.enqueued_at'] = unix_time_with_ms(Time.at(item['enqueued_at']))
          data['_job.queue']       = item['queue']
          data['_job.duration']    = duration_in_ms(started_at, Time.now)

          logger.public_send(severity,
                             type:          'job.enqueued',
                             short_message: short_message(data),
                             data:          data,
                             timestamp:     started_at,
                            )
        end
      end

      def short_message(data)
        format('%s Enqueued',
               data['_job.klass'],
              )
      end

      def logger
        ServiceLogger.logger
      end
    end
  end
end
