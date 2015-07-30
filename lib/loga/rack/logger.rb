module Loga
  module Rack
    class Logger
      include Utilities

      attr_reader :logger, :taggers
      def initialize(app, logger = nil, taggers = nil)
        @app           = app
        @logger        = logger
        @taggers       = taggers || []
      end

      def call(env)
        request = Loga::Rack::Request.new(env)
        env['loga.request.original_path'] = request.path

        if logger.respond_to?(:tagged)
          logger.tagged(compute_tags(request)) { call_app(request, env) }
        else
          call_app(request, env)
        end
      end

      private

      def call_app(request, env)
        started_at = Time.now
        data = {}

        @app.call(env).tap { |status, _headers, _body| data['status'] = status.to_i }
      ensure
        data['method']     = request.request_method
        data['path']       = request.original_path
        data['params']     = request.filtered_parameters
        data['request_id'] = request.uuid
        data['request_ip'] = request.ip
        data['user_agent'] = request.user_agent
        data['duration']   = duration_in_ms(started_at, Time.now)
        exception          = env['action_dispatch.exception'] || env['sinatra.error']

        message = "#{request.request_method} #{request.filtered_full_path}"

        logger.public_send(exception ? :error : :info,
                           type:       'request',
                           message:    message,
                           event:      { request: data },
                           timestamp:  started_at,
                           exception:  exception,
                          )
      end

      def compute_tags(request)
        taggers.collect do |tag|
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
