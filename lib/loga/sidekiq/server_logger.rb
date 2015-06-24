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
          data = item.dup
          data['klass'] = data.delete('class')
          data['params'] = data.delete('args')
          data['duration']    = duration_in_ms(started_at, Time.now)
          logger.public_send(exception ? :error : :info,
                             type:      'job',
                             message:   short_message(data),
                             event:     data,
                             timestamp: started_at,
                             exception: exception,
                            )
        end
      end

      def short_message(data)
        format('%s Processed',
               data['klass'],
              )
      end

      def logger
        Loga.logger
      end
    end
  end
end
