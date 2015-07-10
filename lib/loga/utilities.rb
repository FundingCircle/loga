module Loga
  module Utilities
    def duration_in_ms(started_at, ended_at)
      ((ended_at - started_at) * 1000).round
    end
  end
end
