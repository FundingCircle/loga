require 'loga'

module Loga
  class Railtie < Rails::Railtie
    config.loga = Loga::Configuration.new

    initializer :loga_initialize_logger, before: :initialize_logger do |app|
      if Rails::VERSION::MAJOR > 3
        config.loga.device.sync = app.config.autoflush_log
      else
        config.loga.device.sync = true
      end

      config.loga.level = Logger.const_get(app.config.log_level.to_s.upcase)
      config.loga.initialize!

      app.config.logger = config.loga.logger
    end

    initializer :loga_middleware do |app|
      app.middleware.insert_after Rails::Rack::Logger,
                                  Loga::Rack::Logger,
                                  app.config.logger,
                                  app.config.log_tags,
                                  ActionDispatch::Request

      if config.loga.silence_rails_rack_logger
        case Rails::VERSION::MAJOR
        when 3 then require 'loga/ext/rails/rack/logger3.rb'
        when 4 then require 'loga/ext/rails/rack/logger4.rb'
        end
      end
    end
  end
end
