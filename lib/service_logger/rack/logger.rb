require 'rack/request'

module ServiceLogger
  module Rack
    class Logger
      def initialize(app)
        @app = app
      end

      def call(env)
        started_at = Time.now
        request    = ::Rack::Request.new(env.dup)
        exception  = nil

        begin
          data                        = {}
          data['_request.method']     = request.request_method
          data['_request.path']       = request.path
          data['_request.params']     = request.params
          data['_request.request_ip'] = request.ip
          data['_request.user_agent'] = request.user_agent

          @app.call(env).tap do |status, _headers, _body|
            data['_request.status'] = status
          end
        rescue Exception => e
          exception = e
          raise e
        ensure
          exception ||= env['action_dispatch.exception']

          data['_request.request_id'] = env['X-Request-Id'] || env['action_dispatch.request_id']
          data['_request.duration']   = duration_in_ms(Time.now, started_at)

          logger.public_send(exception ? :error : :info,
                             type:          'http_request',
                             short_message: short_message(request),
                             data:          data,
                             timestamp:     started_at,
                             exception:     exception,
                            )
        end
      end

      def short_message(request)
        format('%s %s',
               request.request_method,
               request.fullpath,
              )
      end

      def duration_in_ms(ended_at, started_at)
        ((ended_at - started_at) * 1000).round
      end

      def logger
        ServiceLogger.logger
      end
    end
  end
end
