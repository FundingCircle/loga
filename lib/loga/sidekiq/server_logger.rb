module Loga
  module Sidekiq
    class ServerLogger
      include Utilities

      def call(_worker, item, _queue)
        started_at = Time.now
        exception  = nil

        begin
          yield
        rescue Exception => e
          exception = e
          raise e
        ensure
          data = {}
          data['retry']       = item['retry']
          data['klass']       = item['class']
          data['jid']         = item['jid']
          data['params']      = item['args']
          data['enqueued_at'] = extract_unix_timestamp(item['enqueued_at'])
          data['queue']       = item['queue']
          data['retry_count'] = item['retry_count']
          data['duration']    = duration_in_ms(started_at, Time.now)
          data['failed_at']   = extract_unix_timestamp(item['failed_at'])
          data['retried_at']  = extract_unix_timestamp(item['retried_at'])

          logger.public_send(exception ? :error : :info,
                             type:          'job_processed',
                             short_message: short_message(data),
                             data:          { 'job' => data },
                             timestamp:     started_at,
                             exception:     exception,
                            )
        end
      end

      def short_message(data)
        format('%s Processed',
               data['klass'],
              )
      end

      def extract_unix_timestamp(timestamp)
        return if timestamp.nil?
        unix_time_with_ms Time.at(timestamp)
      end

      def logger
        Loga.logger
      end
    end
  end
end
