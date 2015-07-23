require 'rails/rack/logger'

module Rails
  module Rack
    class Logger
      protected

      def call_app(_request, env)
        @app.call(env)
      ensure
        ActiveSupport::LogSubscriber.flush_all!
      end

      private

      def compute_tags(_request)
        []
      end
    end
  end
end
