module Loga
  module Rack
    class Logger
      include Utilities

      def initialize(app)
        @app = app
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

      # rubocop:disable Metrics/LineLength
      def set_data
        data['method']     = request.request_method
        data['path']       = request.original_path
        data['params']     = request.filtered_parameters
        data['request_id'] = request.uuid
        data['request_ip'] = request.ip
        data['user_agent'] = request.user_agent
        data['controller'] = request.controller_action_name if request.controller_action_name
        data['duration']   = duration_in_ms(started_at, Time.now)
      end
      # rubocop:enable Metrics/LineLength

      def send_message
        event = Loga::Event.new(
          data:       { request: data },
          exception:  compute_exception,
          message:    compute_message,
          timestamp:  started_at,
          type:       'request',
        )
        logger.public_send(compute_level, event)
      end

      def logger
        Loga.logger
      end

      def compute_message
        '%{method} %{filtered_full_path} %{status} in %{duration}ms' % {
          method:             request.request_method,
          filtered_full_path: request.filtered_full_path,
          status:             data['status'],
          duration:           data['duration'],
        }
      end

      def compute_level
        compute_exception ? :error : :info
      end

      def compute_exception
        filter_exceptions.include?(exception.class.to_s) ? nil : exception
      end

      def exception
        env['loga.exception'] || env['action_dispatch.exception'] ||
          env['sinatra.error'] || env['rack.exception']
      end

      def filter_exceptions
        Loga.configuration.filter_exceptions
      end

      def compute_tags(request)
        tags.map do |tag|
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

      def tags
        Loga.configuration.tags
      end
    end
  end
end
