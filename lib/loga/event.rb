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

    private

    # Guard against Encoding::UndefinedConversionError
    # http://stackoverflow.com/questions/13003287/encodingundefinedconversionerror
    def safe_encode(text)
      text.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
    end
  end
end
