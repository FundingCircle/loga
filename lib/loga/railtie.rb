require 'loga'

module Loga
  class Railtie < Rails::Railtie
    class InitializeLogger
      def initialize(app)
        @app = app
      end

      def call
        app.config.logger = begin
          loga.tap do |config|
            config.device.sync = sync
            config.level = constantized_log_level
          end.initialize!

          loga.logger
        rescue
          STDERR.write('Loga could not be initialized. ' \
                       'Using default Rails logger.')
          nil
        end
      end

      private

      attr_reader :app

      def loga
        app.config.loga
      end

      def sync
        Rails::VERSION::MAJOR > 3 ? app.config.autoflush_log : true
      end

      def constantized_log_level
        Logger.const_get(app.config.log_level.to_s.upcase)
      end
    end

    config.loga = Loga::Configuration.new

    # Reset Loga default device
    config.loga.device = nil

    initializer :loga_initialize_logger, before: :initialize_logger do |app|
      InitializeLogger.new(app).call if app.config.loga.enable
    end

    initializer :loga_middleware do |app|
      if config.loga.enable
        app.middleware.insert_after Rails::Rack::Logger,
                                    Loga::Rack::Logger,
                                    app.config.logger,
                                    app.config.log_tags

        if config.loga.silence_rails_rack_logger
          case Rails::VERSION::MAJOR
          when 3 then require 'loga/ext/rails/rack/logger3.rb'
          when 4 then require 'loga/ext/rails/rack/logger4.rb'
          end
        end

        app.config.colorize_logging = false
      end
    end
  end
end
