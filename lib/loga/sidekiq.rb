require 'loga/sidekiq/job_logger'

module Loga
  module Sidekiq
    def self.configure_logging
      return unless defined?(::Sidekiq)
      return if Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new('5.0')

      ::Sidekiq.configure_server do |config|
        config.options[:job_logger] = Loga::Sidekiq::JobLogger
      end

      ::Sidekiq.logger = Loga.configuration.logger
    end
  end
end
