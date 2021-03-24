module Loga
  module Rack
    class Logger
      include Utilities

      def initialize(app)
        @app = app
      end

      def call(env, started_at = Time.now)
        request = Loga::Rack::Request.new(env)
        env['loga.request.original_path'] = request.path

        if logger.respond_to?(:tagged)
          logger.tagged(compute_tags(request)) { call_app(request, env, started_at) }
        else
          call_app(request, env, started_at)
        end
      end

      private

      def call_app(request, env, started_at)
        status, _headers, _body = @app.call(env)
      ensure
        data = generate_data(request, status, started_at)

        exception = compute_exception(env)

        event = Loga::Event.new(
          data:       { request: data },
          exception:  exception,
          message:    compute_message(request, data),
          timestamp:  started_at,
          type:       'request',
        )

        exception ? logger.error(event) : logger.info(event)
      end

      def generate_data(request, status, started_at)
        {
          'method' => request.request_method,
          'path' => request.original_path,
          'params' => request.filtered_parameters,
          'request_id' => request.uuid,
          'request_ip' => request.ip,
          'user_agent' => request.user_agent,
          'duration' => duration_in_ms(started_at, Time.now),
          'status' => status.to_i,
        }.tap { |d| d['controller'] = request.controller_action_name if request.controller_action_name }
      end

      def logger
        Loga.logger
      end

      def compute_message(request, data)
        '%<method>s %<filtered_full_path>s %<status>d in %<duration>dms' % {
          method:             request.request_method,
          filtered_full_path: request.filtered_full_path,
          status:             data['status'],
          duration:           data['duration'],
        }
      end

      def compute_exception(env)
        exception =
          env['loga.exception'] || env['action_dispatch.exception'] ||
          env['sinatra.error'] || env['rack.exception']

        filter_exceptions.include?(exception.class.to_s) ? nil : exception
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
