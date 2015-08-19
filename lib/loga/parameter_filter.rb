module Loga
  class ParameterFilter
    FILTERED = '[FILTERED]'.freeze

    attr_accessor :filters

    def initialize(filters)
      @filters = filters
    end

    def filter(params)
      compiled_filters.call(params)
    end

    private

    def compiled_filters
      @compiled_filters ||= CompiledFilter.compile(filters)
    end

    class CompiledFilter
      def self.compile(filters)
        ->(params) { params.dup } if filters.empty?

        regexps = []
        strings = []

        filters.each do |item|
          if item.is_a?(Regexp)
            regexps << item
          else
            strings << Regexp.escape(item.to_s)
          end
        end

        regexps << Regexp.new(strings.join('|'), true) unless strings.empty?
        new regexps
      end

      attr_reader :regexps

      def initialize(regexps)
        @regexps = regexps
      end

      def call(original_params)
        filtered_params = {}

        original_params.each do |key, value|
          if regexps.any? { |r| key =~ r }
            value = FILTERED
          elsif value.is_a?(Hash)
            value = call(value)
          elsif value.is_a?(Array)
            value = value.map { |v| v.is_a?(Hash) ? call(v) : v }
          end

          filtered_params[key] = value
        end

        filtered_params
      end
    end
  end
end
