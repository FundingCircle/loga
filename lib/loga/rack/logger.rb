module Loga
  module Rack
    class Logger
      include Utilities

      attr_reader :logger, :taggers
      def initialize(app, logger = nil, taggers = nil, request_klass = Request)
        @app           = app
        @logger        = logger
        @taggers       = taggers || []
        @request_klass = request_klass
      end

      def call(env)
        request = @request_klass.new(env)

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
        data['params']     = request.filtered_parameters
        data['path']       = request.path
        data['request_id'] = request.uuid
        data['request_ip'] = request.ip
        data['user_agent'] = request.user_agent
        original_filtered_path = request.filtered_path
        @app.call(env).tap { |status, _headers, _body| data['status'] = status.to_i }
      ensure
        data['duration'] = duration_in_ms(started_at, Time.now)
        exception        = env['action_dispatch.exception'] || env['sinatra.error']

        message = "#{request.request_method} #{original_filtered_path}"

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
