require 'logger'

# rubocop:disable Lint/UnusedMethodArgument, Style/CaseEquality, Style/IfUnlessModifier, Style/GuardClause
module Loga
  # This is a duplication of the ActiveSupport::TaggedLogging.
  module TaggedLogging
    class SimpleFormatter < ::Logger::Formatter
      # This method is invoked when a log event occurs
      def call(severity, timestamp, progname, msg)
        "#{String === msg ? msg : msg.inspect}\n"
      end
    end

    module Formatter
      # This method is invoked when a log event occurs.
      def call(severity, timestamp, progname, msg)
        super(severity, timestamp, progname, "#{tags_text}#{msg}")
      end

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
        # We use our object ID here to avoid conflicting with other instances
        thread_key = @thread_key ||= "activesupport_tagged_logging_tags:#{object_id}".freeze
        Thread.current[thread_key] ||= []
      end

      private

      def tags_text
        tags = current_tags
        if tags.any?
          tags.collect { |tag| "[#{tag}] " }.join
        end
      end
    end

    def self.new(logger)
      # Ensure we set a default formatter so we aren't extending nil!
      logger.formatter ||= SimpleFormatter.new
      logger.formatter.extend Formatter
      logger.extend(self)
    end

    extend Forwardable
    def_delegators :formatter, :push_tags, :pop_tags, :clear_tags!

    def tagged(*tags)
      formatter.tagged(*tags) { yield self }
    end

    def flush
      clear_tags!
      super if defined?(super)
    end
  end
end
# rubocop:enable Lint/UnusedMethodArgument, Style/CaseEquality, Style/IfUnlessModifier, Style/GuardClause
