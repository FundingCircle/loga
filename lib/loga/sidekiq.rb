# frozen_string_literal: true

module Loga
  module Sidekiq
    def self.configure_logging
      return unless defined?(::Sidekiq)
      return if Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new('5.0')

      if Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new('6.0')
        configure_for_sidekiq5
      elsif Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new('7.0')
        configure_for_sidekiq6
      elsif Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new('8.0')
        configure_for_sidekiq7
      elsif Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new('9.0')
        configure_for_sidekiq8
      end
    end

    def self.configure_for_sidekiq5
      require 'loga/sidekiq5/job_logger'

      ::Sidekiq.configure_server do |config|
        config.options[:job_logger] = Loga::Sidekiq5::JobLogger
      end

      ::Sidekiq.logger = Loga.configuration.logger
    end

    def self.configure_for_sidekiq6
      require 'loga/sidekiq6/job_logger'

      ::Sidekiq.configure_server do |config|
        config.options[:job_logger] = Loga::Sidekiq6::JobLogger
      end

      ::Sidekiq.logger = Loga.configuration.logger
    end

    def self.configure_for_sidekiq7
      require 'loga/sidekiq7/job_logger'

      ::Sidekiq.configure_server do |config|
        config[:job_logger] = Loga::Sidekiq7::JobLogger
        config.logger = Loga.configuration.logger
      end
    end

    def self.configure_for_sidekiq8
      require 'loga/sidekiq8/job_logger'

      ::Sidekiq.configure_server do |config|
        config[:job_logger] = Loga::Sidekiq8::JobLogger
        config.logger = Loga.configuration.logger
      end
    end
  end
end
