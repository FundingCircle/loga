module Loga
  class Event
    attr_accessor :data, :exception, :message, :timestamp, :type

    def initialize(opts = {})
      @data      = opts[:data]
      @exception = opts[:exception]
      @message   = opts[:message].to_s
      @timestamp = opts[:timestamp]
      @type      = opts[:type]
    end
  end
end
