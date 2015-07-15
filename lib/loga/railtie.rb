module Loga
  class Railtie < Rails::Railtie
    config.loga = ActiveSupport::OrderedOptions.new

    # Consider using Loga::Configuration object instead
    config.loga.device = STDOUT
    config.loga.silence_rails_rack_logger = true

    initializer :loga_initialize_logger, before: :initialize_logger do |app|
      io = config.loga.device

      io.sync = app.config.autoflush_log if Rails::VERSION::MAJOR > 3

      logger = Loga::TaggedLogging.new(Logger.new(io))
      logger.formatter = Loga::Formatter.new(host:            config.loga.host,
                                             service_name:    config.loga.service_name,
                                             service_version: config.loga.service_version)

      logger.level = Logger.const_get(app.config.log_level.to_s.upcase)

      app.config.logger = logger
    end

    config.after_initialize do |app|
      Loga.configuration.filter_parameters = app.config.filter_parameters
    end

    initializer :loga_middleware do |app|
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
    end
  end
end
