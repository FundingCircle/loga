require 'thread'

module Loga
  class ContextManager
    def self.current
      Thread.current[:__loga_context_manager] ||= new
    end

    def initialize
      @semaphore = Mutex.new

      clear
    end

    def clear
      @semaphore.synchronize do
        @context = {}
      end
    end

    def attach_context(payload)
      @semaphore.synchronize do
        @context.update(payload)
      end
    end

    def retrieve_context
      @semaphore.synchronize { @context }
    end
  end
end
