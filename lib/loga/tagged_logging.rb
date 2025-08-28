# Copy of ActiveSupport::TaggedLogging
#
# Copyright and license information: https://github.com/rails/rails/blob/master/activesupport/MIT-LICENSE
# Original contributors: https://github.com/rails/rails/commits/master/activesupport/lib/active_support/tagged_logging.rb

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'logger'

module Loga
  # rubocop:disable Layout/LineLength
  # Wraps any standard Logger object to provide tagging capabilities.
  #
  #   logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
  #   logger.tagged('BCX') { logger.info 'Stuff' }                            # Logs "[BCX] Stuff"
  #   logger.tagged('BCX', "Jason") { logger.info 'Stuff' }                   # Logs "[BCX] [Jason] Stuff"
  #   logger.tagged('BCX') { logger.tagged('Jason') { logger.info 'Stuff' } } # Logs "[BCX] [Jason] Stuff"
  #
  # This is used by the default Rails.logger as configured by Railties to make
  # it easy to stamp log lines with subdomains, request ids, and anything else
  # to aid debugging of multi-user production applications.
  # rubocop:enable Layout/LineLength
  module TaggedLogging
    module Formatter # :nodoc:
      def tagged(*tags)
        new_tags = push_tags(*tags)
        yield self
      ensure
        pop_tags(new_tags.size)
      end

      def push_tags(*tags)
        tags.flatten.reject(&:blank?).tap do |new_tags|
          current_tags.concat new_tags
        end
      end

      def pop_tags(size = 1)
        current_tags.pop size
      end

      def clear_tags!
        current_tags.clear
      end

      def current_tags
        Thread.current[:loga_tagged_logging_tags] ||= []
      end

      private

      def tags_text
        tags = current_tags
        tags.collect { |tag| "[#{tag}] " }.join if tags.any?
      end
    end

    def self.new(logger)
      # Ensure we set a default formatter so we aren't extending nil!
      # logger.formatter ||= ::Logger::SimpleFormatter.new
      logger.formatter.extend Formatter
      logger.extend(self)
    end

    delegate :push_tags, :pop_tags, :clear_tags!, to: :formatter

    def tagged(*tags)
      formatter.tagged(*tags) { yield self }
    end

    def flush
      clear_tags!
      super if defined?(super)
    end
  end
end
