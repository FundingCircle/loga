require 'loga'

module Loga
  class Railtie < Rails::Railtie
    config.loga = Loga::Configuration.new

    config.silence_rails_rack_logger = true

    initializer :loga_initialize_logger, before: :initialize_logger do |app|
      if Rails::VERSION::MAJOR > 3
        config.loga.device.sync = app.config.autoflush_log
      end

      config.loga.level = Logger.const_get(app.config.log_level.to_s.upcase)
      config.loga.initialize!
      logger = config.loga.logger

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

      if config.silence_rails_rack_logger
        case Rails::VERSION::MAJOR
        when 3 then require 'loga/ext/rails/rack/logger3.rb'
        when 4 then require 'loga/ext/rails/rack/logger4.rb'
        end
      end
    end
  end
end
