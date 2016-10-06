require 'active_support/core_ext/object/blank'

module Loga
  class ServiceVersionStrategies
    # Redirect stderror to /dev/null when git binary or git directory not available
    SCM_GIT       = -> { `git rev-parse --short HEAD 2>/dev/null` }
    REVISION_FILE = -> { begin; File.read('REVISION'); rescue Errno::ENOENT; nil; end }
    DEFAULT       = -> { 'unknown.sha' }
    STRATEGIES    = [SCM_GIT, REVISION_FILE, DEFAULT].freeze

    def self.call
      new.call
    end

    def call
      STRATEGIES.map { |strategy| strategy.call.presence }.compact.first.strip
    end
  end
end
