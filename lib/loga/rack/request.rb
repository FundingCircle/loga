require 'rack/request'

module Loga
  module Rack
    class Request < ::Rack::Request
      ACTION_DISPATCH_REQUEST_ID = 'action_dispatch.request_id'.freeze
      HTTP_X_REQUEST_ID          = 'HTTP_X_REQUEST_ID'.freeze

      def initialize(env)
        super
        @uuid = nil
      end

      def uuid
        @uuid ||= env[ACTION_DISPATCH_REQUEST_ID] || env[HTTP_X_REQUEST_ID]
      end
    end
  end
end
