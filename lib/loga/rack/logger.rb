module Loga
  module Rack
    class Logger
      include Utilities

      def initialize(app)
        @app = app
      end

      def call(env)
        started_at = Time.now
        request    = Request.new(env)

        data               = {}
        data['method']     = request.request_method
        data['path']       = request.path
        data['params']     = sanitize_params(request.params)
        data['request_ip'] = request.ip
        data['user_agent'] = request.user_agent

        smsg = { 'fullpath' => request.fullpath }

        @app.call(env).tap do |status, _headers, _body|
          data['status']     = status
          data['request_id'] = request.uuid
          data['duration']   = duration_in_ms(started_at, Time.now)

          exception = env['action_dispatch.exception'] || env['sinatra.error']

          logger.public_send(exception ? :error : :info,
                             type:       'request',
                             message:    short_message(data, smsg),
                             event:      data,
                             timestamp:  started_at,
                             exception:  exception,
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

      def filter_parameters
        Loga.configuration.filter_parameters
      end

      def sanitize_params(params)
        (params || {}).each_key do |k|
          params[k] = '[FILTERED]' if filter_parameters.include? k
        end
        params
      end
    end
  end
end
