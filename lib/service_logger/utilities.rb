module ServiceLogger
  module Utilities
    def unix_time_with_ms(time)
      "#{time.to_i}.#{time.strftime('%L')}"
    end

    def duration_in_ms(started_at, ended_at)
      ((ended_at - started_at) * 1000).round
    end
  end
end
