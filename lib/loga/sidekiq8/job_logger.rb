# frozen_string_literal: true

# If a future Sidekiq 8.x release introduces breaking changes that require a
# divergent implementation, replace this constant assignment with a dedicated
# class (you can copy the Sidekiq7 implementation as a starting point).

require 'loga/sidekiq7/job_logger'

module Loga
  module Sidekiq8
    JobLogger = Class.new(Loga::Sidekiq7::JobLogger)
  end
end
