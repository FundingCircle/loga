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

      attr_reader :data, :env, :request, :started_at

      def call_app(request, env)
        @data       = {}
        @env        = env
        @request    = request
        @started_at = Time.now

        @app.call(env).tap { |status, _headers, _body| data['status'] = status.to_i }
      ensure
        set_data
        send_message
      end

      def set_data
        data['method']     = request.request_method
        data['path']       = request.original_path
        data['params']     = request.filtered_parameters
        data['request_id'] = request.uuid
        data['request_ip'] = request.ip
        data['user_agent'] = request.user_agent
        data['duration']   = duration_in_ms(started_at, Time.now)
      end

      def send_message
        event = Loga::Event.new(
          data:       { request: data },
          exception:  fetch_exception,
          message:    compute_message,
          timestamp:  started_at,
          type:       'request',
        )
        logger.public_send(compute_level, event)
      end

      def compute_message
        "#{request.request_method} #{request.filtered_full_path}"
      end

      def compute_level
        fetch_exception ? :error : :info
      end

      def fetch_exception
        (env['action_dispatch.exception'] || env['sinatra.error']).tap do |e|
          return filtered_exceptions.include?(e.class.to_s) ? nil : e
        end
      end

      def filtered_exceptions
        %w(ActionController::RoutingError Sinatra::NotFound)
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
