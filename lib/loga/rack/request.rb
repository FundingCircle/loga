require 'rack/request'
require 'rack/utils'

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

      def original_path
        env['loga.request.original_path']
      end

      def filtered_full_path
        @filtered_full_path ||=
          query_string.empty? ? original_path : "#{original_path}?#{filtered_query_string}"
      end

      def filtered_parameters
        @filtered_parameters ||= filtered_query_hash.merge(filtered_form_hash)
      end

      def filtered_query_hash
        @filtered_query_hash ||= filter_hash(query_hash)
      end

      def filtered_form_hash
        @filter_form_hash ||= filter_hash(form_hash)
      end

      private

      def query_hash
        params
        env['rack.request.query_hash'] || {}
      end

      def form_hash
        params
        env['rack.request.form_hash'] || {}
      end

      def filter_hash(hash)
        parameter_filter.filter(hash)
      end

      KV_RE   = '[^&;=]+'
      PAIR_RE = /(#{KV_RE})=(#{KV_RE})/
      def filtered_query_string
        query_string.gsub(PAIR_RE) do |_|
          parameter_filter.filter([[$1, $2]]).first.join('=')
        end
      end

      def parameter_filter
        @filter_parameters ||=
          ParameterFilter.new(loga_filter_parameters | action_dispatch_filter_params)
      end

      def loga_filter_parameters
        Loga.configuration.filter_parameters || []
      end

      def action_dispatch_filter_params
        env['action_dispatch.parameter_filter'] || []
      end
    end
  end
end
