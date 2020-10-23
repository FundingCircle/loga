module Loga
  module Sidekiq
    def self.configure_logging
      return unless defined?(::Sidekiq)
      return if Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new('5.0')

      if Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new('6.0')
        require 'loga/sidekiq5/job_logger'

        ::Sidekiq.configure_server do |config|
          config.options[:job_logger] = Loga::Sidekiq5::JobLogger
        end
      elsif Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new('7.0')
        require 'loga/sidekiq6/job_logger'

        ::Sidekiq.configure_server do |config|
          config.options[:job_logger] = Loga::Sidekiq6::JobLogger
        end
      end

      ::Sidekiq.logger = Loga.configuration.logger
    end
  end
end
