require 'loga'

module Loga
  class Railtie < Rails::Railtie
    class InitializeLogger
      def initialize(app)
        @app = app
      end

      def call
        loga.tap do |config|
          config.sync  = sync
          config.level = app.config.log_level
        end
        loga.initialize!
        app.config.logger = loga.logger
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

    initializer :loga_initialize_logger, before: :initialize_logger do |app|
      InitializeLogger.new(app).call if app.config.loga.enabled
    end

    class InitializeMiddleware
      module ExceptionsCatcher
        # Sets up an alias chain to catch exceptions when Rails middleware does
        def self.included(base) #:nodoc:
          base.send(:alias_method, :render_exception_without_loga, :render_exception)
          base.send(:alias_method, :render_exception, :render_exception_with_loga)
        end

        private

        def render_exception_with_loga(arg, exception)
          env = arg.is_a?(ActionDispatch::Request) ? arg.env : arg
          env['loga.exception'] = exception
          render_exception_without_loga(arg, exception)
        end
      end

      def initialize(app)
        @app = app
      end

      def call
        insert_loga_rack_logger
        disable_rails_rack_logger
        insert_exceptions_catcher
        disable_action_dispatch_debug_exceptions
      end

      private

      attr_reader :app

      def insert_exceptions_catcher
        if defined?(ActionDispatch::DebugExceptions)
          ActionDispatch::DebugExceptions.send(:include, ExceptionsCatcher)
        elsif defined?(ActionDispatch::ShowExceptions)
          ActionDispatch::ShowExceptions.send(:include, ExceptionsCatcher)
        end
      end

      # Removes start of request log
      # (e.g. Started GET "/users" for 127.0.0.1 at 2015-12-24 23:59:00 +0000)
      def disable_rails_rack_logger
        return unless app.config.loga.silence_rails_rack_logger

        case Rails::VERSION::MAJOR
        when 3 then require 'loga/ext/rails/rack/logger3.rb'
        else
          require 'loga/ext/rails/rack/logger.rb'
        end
      end

      def disable_action_dispatch_debug_exceptions
        require 'loga/ext/rails/rack/debug_exceptions.rb'
      end

      def insert_loga_rack_logger
        app.middleware.insert_after Rails::Rack::Logger,
                                    Loga::Rack::Logger,
                                    app.config.logger,
                                    app.config.log_tags
      end
    end

    initializer :loga_initialize_middleware do |app|
      InitializeMiddleware.new(app).call if app.config.loga.enabled
      app.config.colorize_logging = false
    end

    class InitializeInstrumentation
      def call
        remove_existing_log_subscriptions
      end

      private

      def remove_existing_log_subscriptions
        ActionView::Base       if defined?(ActionView::Base)
        ActionController::Base if defined?(ActionController::Base)

        ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
          case subscriber
          when defined?(ActionView::LogSubscriber) && ActionView::LogSubscriber
            unsubscribe(:action_view, subscriber)
          when defined?(ActionController::LogSubscriber) && ActionController::LogSubscriber
            unsubscribe(:action_controller, subscriber)
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
      InitializeInstrumentation.new.call if app.config.loga.enabled
    end
  end
end
