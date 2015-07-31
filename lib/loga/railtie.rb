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

    class InitializeMiddleware
      def initialize(app)
        @app = app
      end

      def call
        insert_loga_rack_logger
        disable_rails_rack_logger
      end

      private

      attr_reader :app

      def disable_rails_rack_logger
        return unless app.config.loga.silence_rails_rack_logger

        case Rails::VERSION::MAJOR
        when 3 then require 'loga/ext/rails/rack/logger3.rb'
        when 4 then require 'loga/ext/rails/rack/logger4.rb'
        end
      end

      def insert_loga_rack_logger
        app.middleware.insert_after Rails::Rack::Logger,
                                    Loga::Rack::Logger,
                                    app.config.logger,
                                    app.config.log_tags
      end
    end

    initializer :loga_initialize_middleware do |app|
      InitializeMiddleware.new(app).call if app.config.loga.enable
      app.config.colorize_logging = false
    end

    class InitializeInstrumentation
      def call
        remove_existing_log_subscriptions
      end

      private

      def remove_existing_log_subscriptions
        ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
          case subscriber
          when ActionView::LogSubscriber
            unsubscribe(:action_view, subscriber)
          end
        end
      end

      def unsubscribe(component, subscriber)
        events = subscriber.public_methods(false).reject { |method| method.to_s == 'call' }
        events.each do |event|
          ActiveSupport::Notifications
            .notifier
            .listeners_for("#{event}.#{component}")
            .each do |listener|
            if listener.instance_variable_get('@delegate') == subscriber
              ActiveSupport::Notifications.unsubscribe listener
            end
          end
        end
      end
    end

    config.after_initialize do |app|
      InitializeInstrumentation.new.call if app.config.loga.enable
    end
  end
end
