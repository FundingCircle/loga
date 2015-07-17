module Loga
  module Rack
    class Logger
      include Utilities

      def initialize(app, taggers = nil)
        @app     = app
        @taggers = taggers || []
      end

      def call(env)
        request = Request.new(env)

        if logger.respond_to?(:tagged)
          logger.tagged(compute_tags(request)) { call_app(request, env) }
        else
          call_app(request, env)
        end
      end

      private

      def call_app(request, env)
        started_at = Time.now

        data               = {}
        data['method']     = request.request_method
        data['params']     = sanitize_params(request.params)
        data['path']       = request.path
        data['request_id'] = request.uuid
        data['request_ip'] = request.ip
        data['user_agent'] = request.user_agent

        smsg = { 'fullpath' => request.fullpath }

        @app.call(env).tap { |status, _headers, _body| data['status'] = status }
      ensure
        data['duration'] = duration_in_ms(started_at, Time.now)
        exception        = env['action_dispatch.exception'] || env['sinatra.error']

        logger.public_send(exception ? :error : :info,
                           type:       'request',
                           message:    message(data, smsg),
                           event:      data,
                           timestamp:  started_at,
                           exception:  exception,
                          )
      end

      def message(data, smsg)
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

      def compute_tags(request)
        @taggers.collect do |tag|
          case tag
          when Proc
            tag.call(request)
          when Symbol
            request.send(tag)
          else
            tag
          end
        end
      end
    end
  end
end
