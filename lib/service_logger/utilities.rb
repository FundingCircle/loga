module ServiceLogger
  module Utilities
    def unix_time_with_ms(time)
      "#{time.to_i}.#{time.strftime('%L')}"
    end
  end
end
