module Loga
  class Event
    attr_accessor :data, :exception, :message, :timestamp, :type

    def initialize(opts = {})
      @data      = opts[:data]
      @exception = opts[:exception]
      @message   = safe_encode(opts[:message])
      @timestamp = opts[:timestamp]
      @type      = opts[:type]
    end

    def to_s
      output = [message_with_time]
      if exception
        output.push exception.to_s
        output.push exception.backtrace.join("\n")
      end
      output.join("\n")
    end

    alias inspect to_s

    private

    def message_with_time
      if timestamp
        "#{timestamp.iso8601(3)} #{message}"
      else
        message
      end
    end

    # Guard against Encoding::UndefinedConversionError
    # http://stackoverflow.com/questions/13003287/encodingundefinedconversionerror
    def safe_encode(text)
      text.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
    end
  end
end
