require 'rails/rack/logger'

module Rails
  module Rack
    class Logger
      private

      def logger
        ::Logger.new('/dev/null')
      end
    end
  end
end
