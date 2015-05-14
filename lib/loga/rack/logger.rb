require 'rack/request'

module Loga
  module Rack
    class Logger
      include Utilities

      def initialize(app)
        @app = app
      end

      def call(env)
        started_at = Time.now
        request    = ::Rack::Request.new(env)

        data               = {}
        data['method']     = request.request_method
        data['path']       = request.path
        data['params']     = request.params
        data['request_ip'] = request.ip
        data['user_agent'] = request.user_agent

        smsg = { 'fullpath' => request.fullpath }

        begin
          @app.call(env).tap do |status, headers, _body|
            data['status']     = status
            data['request_id'] = headers['X-Request-Id']
          end
        rescue Exception => exception
          raise exception
        ensure
          exception ||= env['action_dispatch.exception'] || env['sinatra.error']

          data['request_id'] ||= env['action_dispatch.request_id']
          data['duration']   = duration_in_ms(started_at, Time.now)

          logger.public_send(exception ? :error : :info,
                             type:          'http_request',
                             short_message: short_message(data, smsg),
                             data:          { request: data },
                             timestamp:     started_at,
                             exception:     exception,
                            )
        end
      end

      private

      def short_message(data, smsg)
        format('%s %s',
               data['method'],
               smsg['fullpath'],
              )
      end

      def logger
        Loga.logger
      end
    end
  end
end
