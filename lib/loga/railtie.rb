require 'loga'
require 'loga/log_subscribers/action_mailer'

module Loga
  class Railtie < Rails::Railtie
    config.loga = {}

    # This service class initializes Loga with user options, framework smart
    # options and update Rails logger with Loga
    class InitializeLogger
      def self.call(app)
        new(app).call
      end

      def initialize(app)
        @app = app
      end

      def call
        validate_user_options
        change_tempfile_as_json
        Loga.configure(user_options, rails_options)
        app.config.colorize_logging = false if Loga.configuration.structured?
        app.config.logger = Loga.logger
      end

      private

      attr_reader :app

      def rails_options
        {
          format: format,
          level:  app.config.log_level,
          sync:   sync,
          tags:   app.config.log_tags || [],
        }.merge(device_options)
      end

      def device_options
        Rails.env.test? ? { device: File.open('log/test.log', 'a') } : {}
      end

      def user_options
        app.config.loga
      end

      def format
        Rails.env.production? ? :gelf : :simple
      end

      def sync
        Rails::VERSION::MAJOR > 3 ? app.config.autoflush_log : true
      end

      def validate_user_options
        if user_options[:tags].present?
          raise Loga::ConfigurationError,
                'Configure tags with Rails config.log_tags'
        elsif user_options[:level].present?
          raise Loga::ConfigurationError,
                'Configure level with Rails config.log_level'
        elsif user_options[:filter_parameters].present?
          raise Loga::ConfigurationError,
                'Configure filter_parameters with Rails config.filter_parameters'
        end
      end

      # Fixes encoding error when converting uploaded file to JSON
      def change_tempfile_as_json
        require 'loga/ext/core/tempfile'
      end
    end

    initializer :loga_initialize_logger, before: :initialize_logger do |app|
      InitializeLogger.call(app)
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

      def self.call(app)
        new(app).call
      end

      def initialize(app)
        @app = app
      end

      def call
        insert_loga_rack_logger
        silence_rails_rack_logger
        insert_exceptions_catcher
        silence_action_dispatch_debug_exceptions_logger
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
      def silence_rails_rack_logger
        case Rails::VERSION::MAJOR
        when 3    then require 'loga/ext/rails/rack/logger3.rb'
        when 4..6 then require 'loga/ext/rails/rack/logger.rb'
        else
          raise Loga::ConfigurationError,
                "Rails #{Rails::VERSION::MAJOR} is unsupported"
        end
      end

      # Removes unstructured exception output. Exceptions are logged with
      # Loga::Rack::Logger instead
      def silence_action_dispatch_debug_exceptions_logger
        require 'loga/ext/rails/rack/debug_exceptions.rb'
      end

      def insert_loga_rack_logger
        app.middleware.insert_after Rails::Rack::Logger, Loga::Rack::Logger
      end
    end

    initializer :loga_initialize_middleware do |app|
      InitializeMiddleware.call(app) if Loga.configuration.structured?
    end

    class InitializeInstrumentation
      def self.call
        new.call
      end

      def call
        ensure_subscriptions_attached
        subscribe_to_action_mailer
        remove_log_subscriptions
      end

      private

      def subscribe_to_action_mailer
        LogSubscribers::ActionMailer.attach_to(:action_mailer)
      end

      # Ensure LogSubscribers are attached when available
      def ensure_subscriptions_attached
        ActionView::Base       if defined?(ActionView::Base)
        ActionController::Base if defined?(ActionController::Base)
        ActionMailer::Base     if defined?(ActionMailer::Base)
      end

      def remove_log_subscriptions
        ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
          component = log_subscription_component(subscriber)

          unsubscribe(component, subscriber)
        end
      end

      def log_subscription_component(subscriber) # rubocop:disable CyclomaticComplexity
        case subscriber
        when defined?(ActionView::LogSubscriber) && ActionView::LogSubscriber
          :action_view
        when defined?(ActionController::LogSubscriber) && ActionController::LogSubscriber
          :action_controller
        when defined?(ActionMailer::LogSubscriber) && ActionMailer::LogSubscriber
          :action_mailer
        end
      end

      def unsubscribe(component, subscriber)
        events = subscriber
                 .public_methods(false)
                 .reject { |method| method.to_s == 'call' }
        events.each do |event|
          ActiveSupport::Notifications
            .notifier
            .listeners_for("#{event}.#{component}")
            .each do |listener|
            if listener.instance_variable_get('@delegate') == subscriber
              ActiveSupport::Notifications.unsubscribe(listener)
            end
          end
        end
      end
    end

    config.after_initialize do |_|
      InitializeInstrumentation.call if Loga.configuration.structured?
    end
  end
end
