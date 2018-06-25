require 'rack/request'
require 'rack/utils'

module Loga
  module Rack
    class Request < ::Rack::Request
      ACTION_DISPATCH_REQUEST_ID = 'action_dispatch.request_id'.freeze
      ACTION_CONTROLLER_INSTANCE = 'action_controller.instance'.freeze

      def initialize(env)
        super
        @uuid = nil
      end

      def uuid
        @uuid ||= env[ACTION_DISPATCH_REQUEST_ID]
      end

      alias request_id uuid

      # Builds a namespaced controller name and action name string.
      #
      # class Admin::UsersController
      #   def show
      #   end
      # end
      #
      #  => "Admin::UsersController#show"
      def controller_action_name
        aci && "#{aci.class.name}##{aci.action_name}"
      end

      def original_path
        env['loga.request.original_path']
      end

      # rubocop:disable Metrics/LineLength
      def filtered_full_path
        @filtered_full_path ||=
          query_string.empty? ? original_path : "#{original_path}?#{filtered_query_string}"
      end
      # rubocop:enable Metrics/LineLength

      def filtered_parameters
        @filtered_parameters ||= filtered_query_hash.merge(filtered_form_hash)
      end

      def filtered_query_hash
        @filtered_query_hash ||= filter_hash(query_hash)
      end

      def filtered_form_hash
        @filtered_form_hash ||= filter_hash(form_hash)
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

      KV_RE   = '[^&;=]+'.freeze
      PAIR_RE = /(#{KV_RE})=(#{KV_RE})/
      def filtered_query_string
        query_string.gsub(PAIR_RE) do |_|
          parameter_filter.filter([[$1, $2]]).first.join('=')
        end
      end

      def parameter_filter
        @parameter_filter ||=
          ParameterFilter.new(loga_filter_parameters | action_dispatch_filter_params)
      end

      def loga_filter_parameters
        Loga.configuration.filter_parameters || []
      end

      def action_dispatch_filter_params
        env['action_dispatch.parameter_filter'] || []
      end

      def action_controller_instance
        @action_controller_instance ||= env[ACTION_CONTROLLER_INSTANCE]
      end

      alias aci action_controller_instance
    end
  end
end
