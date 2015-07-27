require 'rack/request'

module Loga
  module Rack
    class Request < ::Rack::Request
      ACTION_DISPATCH_REQUEST_ID = 'action_dispatch.request_id'.freeze

      def initialize(env)
        super
        @uuid = nil
      end

      def uuid
        @uuid ||= env[ACTION_DISPATCH_REQUEST_ID]
      end

      def filtered_path
        @filtered_path ||= query_string.empty? ? path : "#{path}?#{filtered_query_string}"
      end

      def filtered_parameters
        @filtered_parameters ||= params.each_with_object({}) do |(k, v), acc|
          acc[k] = filter_parameters.include?(k) ? '[FILTERED]' : v
        end
      end

      private

      def filter_parameters
        @filter_parameters ||= Loga.configuration.filter_parameters.map(&:to_s)
      end

      def filtered_query_string
        filtered_parameters.inject([]) { |acc, param|
          acc << param.join('=')
        }.join('&')
      end
    end
  end
end
