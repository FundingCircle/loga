require 'logger'

module Loga
  class ContextLogger < ::Logger
    def debug(*args, &block)
      log_message_with_loga_event(DEBUG, *args, &block)
    end

    def info(*args, &block)
      log_message_with_loga_event(INFO, *args, &block)
    end

    def warn(*args, &block)
      log_message_with_loga_event(WARN, *args, &block)
    end

    def error(*args, &block)
      log_message_with_loga_event(ERROR, *args, &block)
    end

    def fatal(*args, &block)
      log_message_with_loga_event(FATAL, *args, &block)
    end

    private

    def log_message_with_loga_event(level, progname, data = {})
      if block_given?
        message, data = yield

        add(level, nil, progname) { build_loga_event(message, data) }
      else
        message = progname

        add(level, nil, build_loga_event(message, data))
      end
    end

    def build_loga_event(message, data)
      if message.is_a?(Loga::Event)
        message.data = (message.data || {}).merge(data || {})
        message
      else
        Loga::Event.new(message: message, data: data)
      end
    end
  end
end
